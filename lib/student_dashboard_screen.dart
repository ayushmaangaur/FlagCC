import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_screen.dart'; // To navigate to the report form
import 'student_login_screen.dart'; // To navigate back on logout

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  // Placeholder data to visualize the "Highlighting" feature
  final List<Map<String, dynamic>> dummyReports = [
    {
      'title': 'Broken Fan Switch',
      'location': 'Academic Block A',
      'date': '2023-10-24',
      'status': 'Pending',
    },
    {
      'title': 'Water Leakage',
      'location': 'Hostel Boys',
      'date': '2023-10-20',
      'status': 'Resolved',
    },
    {
      'title': 'Projector Malfunction',
      'location': 'Library',
      'date': '2023-10-15',
      'status': 'Resolved',
    },
  ];

  // LOGOUT FUNCTION
  Future<void> _signOut() async {
    // 1. Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    // 2. Navigate back to Login Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user email to display in the Dashboard and Drawer
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Student';
    // Simple logic to get a "Name" from the email (everything before the @)
    final userName = userEmail.split('@')[0];

    return Scaffold(
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        // We REMOVED the 'actions' (Logout button) because it's now in the Drawer
      ),

      // --- SIDE DRAWER (MENU) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. The Blue Header part of the menu
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName[0].toUpperCase(), // First letter of name
                  style: const TextStyle(fontSize: 40.0, color: Colors.blueAccent),
                ),
              ),
            ),

            // 2. Menu Items
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Just closes the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Profile Screen when built
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile page coming soon!")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Report History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to History Screen when built
              },
            ),

            const Divider(), // A thin line separator

            // 3. Logout Button (Red color to indicate exit)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _signOut(); // Perform logout
              },
            ),
          ],
        ),
      ),

      // --- MAIN BODY (Same as before) ---
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Text(
              'Hello,',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Report New Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blueAccent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentReportScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Grievance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Report a new issue',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Your Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Future: View All
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List of Reports
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dummyReports.length,
              itemBuilder: (context, index) {
                final report = dummyReports[index];
                final isPending = report['status'] == 'Pending';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isPending
                        ? const BorderSide(color: Colors.orangeAccent, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.orange[100] : Colors.green[100],
                      child: Icon(
                        isPending ? Icons.access_time : Icons.check,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                    ),
                    title: Text(
                      report['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${report['location']} • ${report['date']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}