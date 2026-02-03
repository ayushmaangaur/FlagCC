import 'package:flutter/material.dart';

void main() {
  runApp(const GrievanceApp());
}

class GrievanceApp extends StatelessWidget {
  const GrievanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Grievance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo or Icon Section
              const Icon(
                Icons.school_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),

              // 2. Title Section
              const Text(
                'FlagCC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Report issues. Improve our campus.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              // 3. Login Options Section
              const Text(
                'Continue as:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Student Login Button
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Student Login Placeholder
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentLoginPlaceholder()),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text('STUDENT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Login Button (Outlined style to differentiate)
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to Admin Login Placeholder
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLoginPlaceholder()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('ADMIN'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent, width: 2),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Screens (Just so the buttons work for now) ---

class StudentLoginPlaceholder extends StatelessWidget {
  const StudentLoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Login")),
      body: const Center(child: Text("Student Login Form Goes Here")),
    );
  }
}

class AdminLoginPlaceholder extends StatelessWidget {
  const AdminLoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Login")),
      body: const Center(child: Text("Admin Login Form Goes Here")),
    );
  }
}