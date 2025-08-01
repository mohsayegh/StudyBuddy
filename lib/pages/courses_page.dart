import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('User not logged in.'));
    }

    final coursesRef = FirebaseFirestore.instance
        .collection('courses')
        .where('userId', isEqualTo: uid);

    void _showAddCourseDialog(BuildContext context) {
      final _nameController = TextEditingController();
      final _creditController = TextEditingController();
      String? selectedTerm;
      int? selectedYear;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add New Course'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Course Name'),
                  ),
                  TextField(
                    controller: _creditController,
                    decoration: const InputDecoration(
                      labelText: 'Credit Hours',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Term'),
                    value: selectedTerm,
                    items: ['Spring', 'Summer', 'Fall']
                        .map(
                          (term) =>
                              DropdownMenuItem(value: term, child: Text(term)),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedTerm = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      selectedYear = int.tryParse(val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final credit = int.tryParse(_creditController.text.trim());

                  if (uid.isNotEmpty &&
                      name.isNotEmpty &&
                      credit != null &&
                      selectedTerm != null &&
                      selectedYear != null) {
                    await FirebaseFirestore.instance.collection('courses').add({
                      'userId': uid,
                      'name': name,
                      'creditHours': credit,
                      'isCompleted': false,
                      'semester': {'term': selectedTerm, 'year': selectedYear},
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Courses'),
        backgroundColor: const Color.fromARGB(255, 193, 191, 191),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () => _showAddCourseDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Course'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color.fromARGB(255, 54, 58, 78),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: coursesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          // Group by semester
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final semester = data['semester'];
            final semesterKey = '${semester['term']} ${semester['year']}';
            grouped.putIfAbsent(semesterKey, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: grouped.entries.map((entry) {
              final semester = entry.key;
              final semesterCourses = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(semester, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  ...semesterCourses.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unnamed';
                    final credit = data['creditHours'] ?? '?';
                    final completed = data['isCompleted'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: completed ? Colors.green : null,
                        ),
                        title: Text(name),
                        subtitle: Text('$credit credit hours'),
                        trailing: IconButton(
                          icon: Icon(
                            completed ? Icons.undo : Icons.check,
                            color: completed ? Colors.orange : Colors.green,
                          ),
                          tooltip: completed
                              ? 'Mark as Incomplete'
                              : 'Mark as Completed',
                          onPressed: () {
                            doc.reference.update({'isCompleted': !completed});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
