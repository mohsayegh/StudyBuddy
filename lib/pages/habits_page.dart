import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('User not logged in.'));
    }

    final habitsRef = FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: uid);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Habits'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: habitsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final habits = snapshot.data!.docs;

          if (habits.isEmpty) {
            return const Center(child: Text('No habits found.'));
          }

          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final doc = habits[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled';
              final frequency = data['frequency'] ?? 'daily';
              final doneDates = List<String>.from(data['doneDates'] ?? []);
              final streak = data['streak'] ?? 0;
              final isDoneToday = doneDates.contains(today);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('$frequency · Streak: $streak'),
                  trailing: ElevatedButton(
                    onPressed: isDoneToday
                        ? null
                        : () async {
                            final updatedDates = [...doneDates, today];
                            await doc.reference.update({
                              'doneDates': updatedDates,
                              'lastDone': Timestamp.now(),
                              'streak': streak + 1,
                            });
                          },
                    child: Text(isDoneToday ? 'Done' : 'Mark as Done'),
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
