import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  void _showHabitDialog({DocumentSnapshot? doc}) {
    final data = doc?.data() as Map<String, dynamic>?;
    final titleController = TextEditingController(text: data?['title'] ?? '');
    String frequency = data?['frequency'] ?? 'daily';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? 'Add Habit' : 'Edit Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Habit Title'),
            ),
            DropdownButtonFormField<String>(
              value: frequency,
              items: [
                'daily',
                'weekly',
              ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) => frequency = val ?? 'daily',
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
          ],
        ),
        actions: [
          if (doc != null)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text('Delete this habit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await doc.reference.delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habit deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final habitData = {
                'title': title,
                'frequency': frequency,
                'userId': uid,
                'createdAt': FieldValue.serverTimestamp(),
                'lastDone': null,
                'doneDates': [],
              };
              if (doc == null) {
                await FirebaseFirestore.instance
                    .collection('habits')
                    .add(habitData);
              } else {
                await doc.reference.update({
                  'title': title,
                  'frequency': frequency,
                });
              }
              Navigator.pop(context);
            },
            child: Text(doc == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  List<String> getLast7Days() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) =>
          DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 6 - i))),
    );
  }

  Widget buildBarChart(List<String> doneDates) {
    final last7 = getLast7Days();
    final completedSet = doneDates.toSet();

    final bars = last7.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final isDone = completedSet.contains(date);

      return BarChartRodData(
        toY: isDone ? 1 : 0,
        color: isDone ? Colors.green : Colors.grey[400],
        width: 12,
        borderRadius: BorderRadius.circular(4),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < 7) {
                        final date = last7[index];
                        final weekday = DateFormat.E().format(
                          DateTime.parse(date),
                        );
                        return Text(weekday[0]);
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: List.generate(
                7,
                (i) => BarChartGroupData(x: i, barRods: [bars[i]]),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              maxY: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${doneDates.where((d) => last7.contains(d)).length}/7 this week',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Center(child: Text('User not logged in'));

    final habitsRef = FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: const Color.fromARGB(255, 193, 191, 191),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitDialog(),
        backgroundColor: const Color.fromARGB(255, 193, 191, 191),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: habitsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No habits found'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final frequency = data['frequency'] ?? 'daily';
              final doneDates = List<String>.from(data['doneDates'] ?? []);
              final lastDone = data['lastDone'] != null
                  ? (data['lastDone'] as Timestamp).toDate()
                  : null;
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final alreadyDoneToday = doneDates.contains(todayStr);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showHabitDialog(doc: doc),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Frequency: $frequency'),
                      const SizedBox(height: 12),
                      buildBarChart(doneDates),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: alreadyDoneToday
                            ? null
                            : () async {
                                final ref = doc.reference;
                                doneDates.add(todayStr);
                                await ref.update({
                                  'doneDates': doneDates,
                                  'lastDone': DateTime.now(),
                                });
                              },
                        icon: const Icon(Icons.check),
                        label: Text(
                          alreadyDoneToday ? 'Completed Today' : 'Mark as Done',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alreadyDoneToday
                              ? Colors.grey
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
