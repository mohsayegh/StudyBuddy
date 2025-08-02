import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy/pages/assignment_page.dart';
import 'package:studybuddy/pages/landing_page.dart';
import 'theme_provider.dart'; // your custom ThemeProvider file
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const StudyBuddyApp(),
    ),
  );
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'StudyBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/tasks': (context) => const AssignmentPage(),
      },
    );
  }
}
