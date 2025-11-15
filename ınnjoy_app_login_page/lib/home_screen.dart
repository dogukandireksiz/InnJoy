import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  Future<void> _logout(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B2F),
        title: const Text("Home", style: TextStyle(color: Colors.amber)),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Hoş geldin, $userName!",
          style: const TextStyle(color: Colors.white, fontSize: 26),
        ),
      ),
    );
  }
}
