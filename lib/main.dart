import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'student_login_screen.dart'; // Ensure this file exists

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the .env file containing your secret keys
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase using the keys from .env
  // We use '!' to assert that the values exist. If .env is missing, this will crash (intentionally)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const GrievanceApp());
}

class GrievanceApp extends StatelessWidget {
  const GrievanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Grievance System',
      debugShowCheckedModeBanner: false, // Removes the red "Debug" banner
      theme: ThemeData(
        // Defining a consistent color scheme for the app
        primarySwatch: Colors.blue,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
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
              // 1. Logo Section
              const Icon(
                Icons.school_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),

              // 2. Title Section
              const Text(
                'Campus Grievance\nReporting System',
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

              // Student Login Button -> Navigates to StudentLoginScreen
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StudentLoginScreen()),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text('STUDENT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Login Button -> Placeholder for now
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminLoginPlaceholder()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('ADMIN'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent, width: 2),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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

// --- Admin Placeholder (Kept here until we build the Admin file) ---
class AdminLoginPlaceholder extends StatelessWidget {
  const AdminLoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Login")),
      body: const Center(child: Text("Admin Logic coming soon...")),
    );
  }
}