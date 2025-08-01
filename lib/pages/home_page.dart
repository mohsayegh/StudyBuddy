import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String? _error;

  String? _quote;
  bool _quoteLoading = true;

  double _quoteOpacity = 0.0;
  double _cardOpacity = 0.0;
  Offset _cardOffset = const Offset(0, 0.1);

  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadQuote();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadQuote();
  }

  void _loadQuote() async {
    setState(() {
      _quoteOpacity = 0.0; // fade out first
      _quoteLoading = true;
    });

    try {
      final quote = await fetchMotivationalQuote();

      setState(() {
        _quote = quote;
        _quoteLoading = false;
      });

      // Delay fade-in slightly after setting quote
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _quoteOpacity = 1.0;
          });
        }
      });
    } catch (e) {
      setState(() {
        _quote = "Keep going. You've got this.";
        _quoteLoading = false;
        _quoteOpacity = 1.0;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() {
        _error = 'User not logged in.';
        _loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Profile not found.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  Future<String> fetchMotivationalQuote() async {
    final response = await http.get(
      Uri.parse('https://zenquotes.io/api/random'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data[0]['q'] + ' — ' + data[0]['a'];
    } else {
      throw Exception('Failed to load quote');
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyBuddy Home'),
        backgroundColor: const Color.fromARGB(255, 193, 191, 191),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            '${_userData?['name'] ?? 'Student'} 👋',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (!_quoteLoading && _quote != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AnimatedOpacity(
                              opacity: _quoteOpacity,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  '"$_quote"',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700],
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 12),
                  Text('🎓 University: ${_userData?['university'] ?? '—'}'),
                  Text('🧠 Major: ${_userData?['major'] ?? '—'}'),
                ],
              ),
            ),
    );
  }
}
