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
  Map<String, List<DocumentSnapshot>> semesterCourses = {};
  Map<String, int> semesterCreditTotals = {};
  int? totalDegreeCredits;
  bool showGPA = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSemester();
    _loadTotalDegreeCredits();
    _fetchCourses();
  }

  void _showCourseSettingsDialog(BuildContext context) {
    final _creditsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Course Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Credits Required for Degree',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final total = int.tryParse(_creditsController.text.trim());
                if (uid != null && total != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({
                        'totalDegreeCredits': total,
                      }, SetOptions(merge: true));
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

  Future<bool?> _showEditCourseDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final _nameController = TextEditingController(text: data['name']);
    final _creditController = TextEditingController(
      text: data['creditHours'].toString(),
    );
    final _gpaController = TextEditingController(
      text: data['gpa']?.toString() ?? '',
    );
    String selectedTerm = data['semester']['term'];
    int selectedYear = data['semester']['year'];

    return showDialog<bool>(
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
                  decoration: const InputDecoration(labelText: 'Credit Hours'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _gpaController,
                  decoration: const InputDecoration(labelText: 'GPA'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  onChanged: (value) => selectedTerm = value ?? selectedTerm,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: selectedYear.toString(),
                  ),
                  onChanged: (val) =>
                      selectedYear = int.tryParse(val) ?? selectedYear,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () =>
                  Navigator.pop(context, true), // return true to delete
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final credit = int.tryParse(_creditController.text.trim());
                final gpa = double.tryParse(_gpaController.text.trim());

                if (name.isNotEmpty && credit != null) {
                  await doc.reference.update({
                    'name': name,
                    'creditHours': credit,
                    'gpa': gpa,
                    'semester': {'term': selectedTerm, 'year': selectedYear},
                  });
                  _fetchCourses(); // refresh after saving
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

  void _showAddCourseDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _creditController = TextEditingController();
    final _gpaController = TextEditingController();
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
                  decoration: const InputDecoration(labelText: 'Credit Hours'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _gpaController,
                  decoration: const InputDecoration(
                    labelText: 'GPA (Optional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  onChanged: (value) => selectedTerm = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => selectedYear = int.tryParse(val),
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
                final gpa = double.tryParse(_gpaController.text.trim());

                if (name.isNotEmpty &&
                    credit != null &&
                    selectedTerm != null &&
                    selectedYear != null) {
                  await FirebaseFirestore.instance.collection('courses').add({
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'name': name,
                    'creditHours': credit,
                    'gpa': gpa,
                    'isCompleted': false,
                    'semester': {'term': selectedTerm, 'year': selectedYear},
                  });

                  _fetchCourses(); // refresh list
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

  Future<void> _loadTotalDegreeCredits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      totalDegreeCredits = data['totalDegreeCredits'];
    });
  }

  Future<void> _loadCurrentSemester() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() as Map<String, dynamic>;

    if (data['currentSemester'] != null) {
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

  Future<void> _fetchCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('userId', isEqualTo: uid)
        .get();

    final Map<String, List<DocumentSnapshot>> grouped = {};
    final Map<String, int> creditTotals = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final term = data['semester']['term'];
      final year = data['semester']['year'];

      final credits = (data['creditHours'] ?? 0);
      final creditInt = credits is int
          ? credits
          : (credits as num).toInt(); // fix casting

      final semesterKey = '$term $year';
      grouped.putIfAbsent(semesterKey, () => []).add(doc);
      creditTotals[semesterKey] = ((creditTotals[semesterKey] ?? 0) + creditInt)
          .toInt();
    }

    setState(() {
      semesterCourses = grouped;
      semesterCreditTotals = creditTotals;
    });
  }

  double calculateGPA(List<QueryDocumentSnapshot> courses) {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var doc in courses) {
      final data = doc.data() as Map<String, dynamic>;
      final credit = (data['creditHours'] ?? 0).toDouble();
      final grade = data['gpa'];
      if (grade != null) {
        totalPoints += grade * credit;
        totalCredits += credit;
      }
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  // _showAddCourseDialog and _showEditCourseDialog remain unchanged
  // [You can keep them as-is from your version]

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('User not logged in.'));
    }

    final allDocs = semesterCourses.values
        .expand((list) => list)
        .toList()
        .cast<DocumentSnapshot>();
    final completedDocs = semesterCourses.values.expand((list) => list).where((
      doc,
    ) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isCompleted'] == true;
    }).toList();

    final allGpa = calculateGPA(completedDocs.cast<QueryDocumentSnapshot>());
    final completedCredits = semesterCourses.values
        .expand((list) => list)
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((data) => data['isCompleted'] == true)
        .fold<int>(
          0,
          (sum, data) => sum + ((data['creditHours'] ?? 0) as num).toInt(),
        );

    final double progress =
        (totalDegreeCredits != null && totalDegreeCredits! > 0)
        ? (completedCredits / totalDegreeCredits!).clamp(0.0, 1.0)
        : 0.0;

    final int remaining = totalDegreeCredits != null
        ? totalDegreeCredits! - completedCredits
        : 0;

    final String percentText =
        '${(progress * 100).toStringAsFixed(0)}% complete';

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Course Settings',
            onPressed: () => _showCourseSettingsDialog(context),
          ),
        ],
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
      body: semesterCourses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall GPA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // GPA value with toggle button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              showGPA ? allGpa.toStringAsFixed(2) : '•••',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showGPA
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  showGPA = !showGPA;
                                });
                              },
                            ),
                          ],
                        ),

                        if (totalDegreeCredits != null) ...[
                          const SizedBox(height: 24),

                          // Progress Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎓 Completed $completedCredits / $totalDegreeCredits credits',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '$remaining credits remaining',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 1.0
                                            ? Colors.green
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    percentText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // ✅ 🎉 Motivational Message after progress row
                          if (completedCredits >= 10) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Great job! You’ve completed over 10 credits — keep it up! 🎉',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                ...semesterCourses.entries.map((entry) {
                  final semester = entry.key;
                  final semesterCourses = entry.value;
                  final credits = semesterCreditTotals[semester] ?? 0;

                  return ExpansionTile(
                    title: Text(
                      '$semester ($credits credits)',
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
                      final gpa = data['gpa'];
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
                            onPressed: () async {
                              await doc.reference.update({
                                'isCompleted': !completed,
                              });
                              _fetchCourses(); // Refresh UI
                            },
                          ),
                          title: Text(name),
                          subtitle: Text(
                            '$credit credit hours${gpa != null ? ' | GPA: $gpa' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Edit Course',
                            onPressed: () async {
                              final result = await _showEditCourseDialog(
                                context,
                                doc,
                              );
                              if (result == true) {
                                await doc.reference.delete();
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
    );
  }
}
