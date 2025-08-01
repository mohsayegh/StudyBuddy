import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String? currentSemester;
  final Set<String> expandedSemesters = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentSemester();
  }

  Future<void> _loadCurrentSemester() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null && data['currentSemester'] != null) {
      final term = data['currentSemester']['term'];
      final year = data['currentSemester']['year'];
      if (term != null && year != null) {
        setState(() {
          currentSemester = '$term $year';
          expandedSemesters.add(currentSemester!);
        });
      }
    }
  }

  String getCurrentSemesterKey() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    String term;
    if (month >= 1 && month <= 4) {
      term = 'Spring';
    } else if (month >= 5 && month <= 7) {
      term = 'Summer';
    } else {
      term = 'Fall';
    }
    return '$term $year';
  }

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

    void _showEditCourseDialog(BuildContext context, DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>;

      final _nameController = TextEditingController(text: data['name']);
      final _creditController = TextEditingController(
        text: data['creditHours'].toString(),
      );
      String selectedTerm = data['semester']['term'];
      int selectedYear = data['semester']['year'];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Course'),
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
                      if (value != null) selectedTerm = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: selectedYear.toString(),
                    ),
                    onChanged: (val) => selectedYear = int.tryParse(val) ?? 0,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                        'Are you sure you want to delete this course?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final deletedData = doc.data() as Map<String, dynamic>;
                    final deletedRef = doc.reference;

                    await deletedRef.delete();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Course deleted'),
                        backgroundColor: Colors.redAccent,
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Colors.white,
                          onPressed: () async {
                            await deletedRef.set(deletedData);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Course restored'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final credit = int.tryParse(_creditController.text.trim());

                  if (name.isNotEmpty && credit != null && selectedYear > 0) {
                    await doc.reference.update({
                      'name': name,
                      'creditHours': credit,
                      'semester': {'term': selectedTerm, 'year': selectedYear},
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
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

              return ExpansionTile(
                title: Text(
                  semester,
                  style: TextStyle(
                    fontSize: semester == currentSemester ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: semester == currentSemester
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),

                initiallyExpanded: expandedSemesters.contains(semester),
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    if (isExpanded) {
                      expandedSemesters.add(semester);
                    } else {
                      expandedSemesters.remove(semester);
                    }
                  });
                },
                children: semesterCourses.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unnamed';
                  final credit = data['creditHours'] ?? '?';
                  final completed = data['isCompleted'] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: completed ? Colors.green : null,
                        ),
                        onPressed: () {
                          doc.reference.update({'isCompleted': !completed});
                        },
                      ),
                      title: Text(name),
                      subtitle: Text('$credit credit hours'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        tooltip: 'Edit Course',
                        onPressed: () => _showEditCourseDialog(context, doc),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
