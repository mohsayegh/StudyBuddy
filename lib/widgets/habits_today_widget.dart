import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HabitsTodayWidget extends StatelessWidget {
  const HabitsTodayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧠 Today\'s Habits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('habits')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading habits.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('No habits yet.');
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final List doneDates = data['doneDates'] ?? [];
                    final isDoneToday = doneDates.contains(today);

                    return CheckboxListTile(
                      value: isDoneToday,
                      title: Text(title),
                      onChanged: (val) async {
                        final updatedDates = List<String>.from(doneDates);

                        if (val == true && !updatedDates.contains(today)) {
                          updatedDates.add(today);
                        } else if (val == false &&
                            updatedDates.contains(today)) {
                          updatedDates.remove(today);
                        }

                        await FirebaseFirestore.instance
                            .collection('habits')
                            .doc(doc.id)
                            .update({'doneDates': updatedDates});
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
