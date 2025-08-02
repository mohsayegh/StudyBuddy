import 'package:flutter/material.dart';
import 'package:studybuddy/pages/assignment_page.dart';
import 'package:studybuddy/pages/courses_page.dart';
import 'package:studybuddy/pages/habits_page.dart';
import 'package:studybuddy/pages/profile_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final int _initialPage = 2; // Home is now index 2
  late final PageController _pageController;

  int _selectedIndex = 2;

  final List<Widget> _pages = const [
    CoursesPage(), // index 0
    AssignmentPage(), // index 1
    HomePage(), // index 2 — center
    HabitsPage(), // index 3
    ProfilePage(), // index 4
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Habits'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        items: _navItems,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
