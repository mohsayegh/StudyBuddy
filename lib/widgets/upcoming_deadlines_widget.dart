import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpcomingDeadlinesWidget extends StatelessWidget {
  const UpcomingDeadlinesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final assignmentQuery = FirebaseFirestore.instance
        .collection('assignments')
        .where('dueDate', isGreaterThanOrEqualTo: now)
        .where('dueDate', isLessThanOrEqualTo: nextWeek)
        .orderBy('dueDate');

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
              '📅 Upcoming Deadlines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: assignmentQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading deadlines.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('No upcoming assignments!');
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final dueDate = (data['dueDate'] as Timestamp).toDate();
                    final formattedDate =
                        '${dueDate.month}/${dueDate.day}'; // MM/DD
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text('Due: $formattedDate'),
                      leading: const Icon(Icons.assignment_turned_in_outlined),
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
