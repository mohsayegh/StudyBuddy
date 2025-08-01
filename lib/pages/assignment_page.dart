import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final CollectionReference assignmentsRef = FirebaseFirestore.instance
      .collection('assignments');

  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];

  String? _selectedCourseId;
  bool _onlyToday = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .get();

    setState(() {
      _courses = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Unnamed'})
          .toList();
    });
  }

  Future<void> _addAssignment() async {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    String? selectedCourseId;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: const Text('Pick Due Date'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Course (optional)',
                  ),
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(course['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    selectedCourseId = value;
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
                if (titleController.text.isNotEmpty && selectedDate != null) {
                  await assignmentsRef.add({
                    'title': titleController.text,
                    'dueDate': selectedDate,
                    'courseId': selectedCourseId ?? '',
                    'isCompleted': false,
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

  Future<void> _editAssignment(
    String id,
    Map<String, dynamic> currentData,
  ) async {
    final titleController = TextEditingController(text: currentData['title']);
    DateTime selectedDate = (currentData['dueDate'] as Timestamp).toDate();
    String selectedCourseId = currentData['courseId'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: const Text('Pick New Due Date'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCourseId.isEmpty ? null : selectedCourseId,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem<String>(
                          value: course['id'],
                          child: Text(course['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    selectedCourseId = value ?? '';
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
                if (titleController.text.isNotEmpty) {
                  await assignmentsRef.doc(id).update({
                    'title': titleController.text,
                    'dueDate': selectedDate,
                    'courseId': selectedCourseId,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure you want to delete this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await assignmentsRef.doc(id).delete();
    }
  }

  Future<void> _toggleCompleted(String id, bool currentStatus) async {
    await assignmentsRef.doc(id).update({'isCompleted': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAssignment,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: assignmentsRef.orderBy('dueDate').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final courseId = data['courseId'] ?? '';
            final dueDate = (data['dueDate'] as Timestamp).toDate();

            final matchesCourse =
                _selectedCourseId == null || _selectedCourseId == courseId;

            final matchesToday =
                !_onlyToday ||
                (dueDate.year == DateTime.now().year &&
                    dueDate.month == DateTime.now().month &&
                    dueDate.day == DateTime.now().day);

            return matchesCourse && matchesToday;
          }).toList();

          final Map<String, List<QueryDocumentSnapshot>> grouped = {};

          for (var doc in filteredDocs) {
            final courseId =
                (doc.data() as Map<String, dynamic>)['courseId'] ?? '';
            grouped.putIfAbsent(courseId, () => []).add(doc);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCourseId,
                        hint: const Text('Filter by course'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Courses'),
                          ),
                          ..._courses.map(
                            (course) => DropdownMenuItem(
                              value: course['id'],
                              child: Text(course['name']),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: _onlyToday,
                      onChanged: (val) {
                        setState(() {
                          _onlyToday = val ?? false;
                        });
                      },
                    ),
                    const Text('Today only'),
                  ],
                ),
              ),
              Expanded(
                child: grouped.isEmpty
                    ? const Center(
                        child: Text('No assignments match your filter.'),
                      )
                    : ListView(
                        children: grouped.entries.map((entry) {
                          final courseId = entry.key;
                          final assignments = entry.value;
                          final courseName = _courses.firstWhere(
                            (c) => c['id'] == courseId,
                            orElse: () => {'name': 'No course'},
                          )['name'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  '📘 $courseName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...assignments.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title'] ?? '';
                                final isCompleted =
                                    data['isCompleted'] ?? false;
                                final dueDate = (data['dueDate'] as Timestamp)
                                    .toDate();
                                final formattedDate =
                                    '${dueDate.month}/${dueDate.day}/${dueDate.year}';

                                return ListTile(
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text('Due: $formattedDate'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: isCompleted,
                                        onChanged: (_) => _toggleCompleted(
                                          doc.id,
                                          isCompleted,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _editAssignment(doc.id, data),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDelete(doc.id),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
