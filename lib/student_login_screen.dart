import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_dashboard_screen.dart'; // Navigates here on success
import 'student_signup_screen.dart';    // Navigates here to register

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  // 1. Controllers to retrieve text from inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. Loading state to disable button while processing
  bool _isLoading = false;

  // --- LOGIC: SIGN IN FUNCTION ---
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Attempt to sign in (Checks email/password only)
      final AuthResponse res =
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;

      if (user != null) {
        // 2. SECURITY CHECK: Check the user's role
        // We use safe navigation (?.) because 'role' might be null for old users
        final String? role = user.userMetadata?['role'];

        if (role == 'student') {
          // CORRECT ROLE: Allow access
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const StudentDashboardScreen()),
            );
          }
        } else {
          // WRONG ROLE: It's an Admin (or someone else) trying to log in here
          await Supabase.instance.client.auth.signOut(); // Log them out immediately

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: Use the Admin Login portal.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      // Handle Supabase specific errors (e.g., "Invalid login credentials")
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Turn off loading spinner regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- UI: BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                const Icon(Icons.school, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 20),

                // Welcome Text
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Email Input
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Password Input
                TextField(
                  controller: _passwordController,
                  obscureText: true, // Hides the password
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 18),
                  ),
                ),

                const SizedBox(height: 24),

                // "Register Here" Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        // Navigate to the Sign Up Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const StudentSignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Register Here',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}