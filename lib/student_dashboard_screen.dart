import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_screen.dart';
import 'student_history_screen.dart';
import 'student_report_detail_screen.dart';
import 'student_login_screen.dart';
import 'community_page.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {

  // --- 1. AUTH & NAVIGATION ---
  Future<void> _signOut() async {
    // Show confirmation dialog before signing out
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
              (route) => false, // Clear navigation stack
        );
      }
    }
  }

  void _goToReportScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentReportScreen()));
  }

  void _goToHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentHistoryScreen()));
  }

  void _goToCommunity() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityPage()));
  }

  void _goToDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReportDetailScreen(report: report),
      ),
    );
  }

  // --- 2. COLOR THEME LOGIC ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green; // Success
      case 'rejected': return Colors.red;   // Alert
      case 'in_review':
      case 'in review': return Colors.blue; // Active
      case 'closed': return Colors.grey;    // Archived
      case 'pending':
      default: return Colors.orange;        // Waiting
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Student';
    final userName = userEmail.split('@')[0];
    final userId = user!.id;

    // Streams
    final myRecentStream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(3);

    final communityStream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(5);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        // --- NEW: LOGOUT BUTTON ON TOP RIGHT ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(userName[0].toUpperCase(), style: const TextStyle(fontSize: 40.0, color: Colors.blueAccent)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blueAccent),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueAccent),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                _goToHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum, color: Colors.blueAccent),
              title: const Text('Community Page'),
              onTap: () {
                Navigator.pop(context);
                _goToCommunity();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,", style: TextStyle(color: Colors.blue[100], fontSize: 16)),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Report New Button
                  Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _goToReportScreen,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Report New Grievance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Found an issue? Let us know.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Recent Reports
                  _buildSectionHeader("Your Recent Reports", onTapViewAll: _goToHistory),
                  const SizedBox(height: 10),
                  _buildReportList(myRecentStream, isCommunity: false),

                  const SizedBox(height: 30),

                  // Community Section
                  _buildSectionHeader("Community Discussions", onTapViewAll: _goToCommunity),
                  const SizedBox(height: 10),
                  _buildReportList(communityStream, isCommunity: true),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTapViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onTapViewAll, child: const Text("View All")),
      ],
    );
  }

  Widget _buildReportList(Stream<List<Map<String, dynamic>>> stream, {required bool isCommunity}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());

        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(isCommunity ? "No active discussions." : "You have no recent reports.", style: const TextStyle(color: Colors.grey))),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final status = report['status'] ?? 'pending';
            final title = report['title'] ?? 'No Title';
            final date = report['created_at'].toString().split('T')[0];

            // --- THEME COLOR APPLICATION ---
            final color = _getStatusColor(status);

            // Anonymity Logic
            final bool isPrivate = (report['privacy'] == 'private');
            final currentUserId = Supabase.instance.client.auth.currentUser!.id;
            final String reportUserId = report['user_id'];
            final String email = report['user_email'] ?? 'User';

            String postedBy;
            if (reportUserId == currentUserId) {
              postedBy = "Me ${isPrivate ? '(Private)' : ''}";
            } else if (isPrivate) {
              postedBy = "Anonymous Student";
            } else {
              postedBy = email.split('@')[0];
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Add a subtle border matching the status color for "My Reports"
                side: isCommunity ? BorderSide(color: Colors.grey.shade200) : BorderSide(color: color.withOpacity(0.3), width: 1),
              ),
              child: ListTile(
                onTap: () => _goToDetails(report),
                leading: CircleAvatar(
                  backgroundColor: isCommunity ? Colors.blue.withOpacity(0.1) : color.withOpacity(0.1),
                  child: Icon(
                      isCommunity ? (isPrivate ? Icons.visibility_off : Icons.forum_outlined) : Icons.assignment,
                      // Theme Color applied to Icon
                      color: isCommunity ? (isPrivate ? Colors.grey : Colors.blue) : color,
                      size: 20
                  ),
                ),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: isCommunity
                    ? Text("By $postedBy", style: TextStyle(color: Colors.grey[600], fontSize: 12))
                    : Text(date),
                trailing: isCommunity
                    ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), // Tint background with status color
                      borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold) // Text matches status color
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}