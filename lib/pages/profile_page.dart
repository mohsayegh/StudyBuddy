import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _universityController = TextEditingController();
  String? _selectedTerm;
  int? _selectedYear;

  final _terms = ['Spring', 'Summer', 'Fall'];
  final _years = List.generate(100, (index) => 2025 + index);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _majorController.text = data['major'] ?? '';
        _universityController.text = data['university'] ?? '';
        _selectedTerm = data['currentSemester']?['term'];
        _selectedYear = data['currentSemester']?['year'];
      });
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text.trim(),
      'major': _majorController.text.trim(),
      'university': _universityController.text.trim(),
      'currentSemester': {'term': _selectedTerm, 'year': _selectedYear},
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _majorController,
              decoration: _inputDecoration('Major'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _universityController,
              decoration: _inputDecoration('University'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTerm,
              decoration: _inputDecoration('Current Semester Term'),
              items: _terms
                  .map(
                    (term) => DropdownMenuItem(value: term, child: Text(term)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedTerm = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: _inputDecoration('Year'),
              items: _years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedYear = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
