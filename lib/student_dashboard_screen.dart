import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_screen.dart';
import 'student_history_screen.dart';
import 'student_report_detail_screen.dart';
import 'community_page.dart';
import 'main.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {

  // --- AUTH & NAVIGATION ---
  Future<void> _signOut() async {
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
          MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
        );
      }
    }
  }

  // --- THE BUG FIX IS HERE ---
  // Added async, await, and setState to force a refresh when returning to this screen
  Future<void> _goToReportScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentReportScreen()));
    setState(() {}); // Forces the dashboard to reload fresh data
  }

  Future<void> _goToHistory() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentHistoryScreen()));
    setState(() {}); // Forces the dashboard to reload fresh data
  }

  Future<void> _goToCommunity() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityPage()));
    setState(() {}); // Forces the dashboard to reload fresh data
  }

  Future<void> _goToDetails(Map<String, dynamic> report) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentReportDetailScreen(report: report)),
    );
    setState(() {}); // Forces the dashboard to reload fresh data
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'in_review':
      case 'in review': return Colors.blue;
      case 'closed': return Colors.grey;
      case 'pending':
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'Student';
    final userName = userEmail.split('@')[0];

    // 1. GET THE LOGGED-IN STUDENT'S ID
    final userId = user!.id;

    // 2. THE FIX: Filter the stream to ONLY fetch this student's reports!
    final myReportsStream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Community Stream (Fetches all public, limited to 5 for the preview)
    final communityStream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(5);

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Welcome back, $userName', style: TextStyle(fontSize: 12, color: Colors.blue[100])),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(userEmail, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout, size: 20), tooltip: 'Sign Out', onPressed: _signOut),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[800]),
              accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(userName[0].toUpperCase(), style: TextStyle(fontSize: 40.0, color: Colors.blue[800])),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.blue[800]),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue[800]),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                _goToHistory();
              },
            ),
            ListTile(
              leading: Icon(Icons.forum, color: Colors.blue[800]),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // --- MY STATS & RECENT REPORTS ---
              StreamBuilder<List<Map<String, dynamic>>>(
                  stream: myReportsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

                    final myReports = snapshot.data!;

                    // Calculate Stats (Now only using data belonging to this student)
                    int total = myReports.length;
                    int pending = myReports.where((r) => r['status'] == 'pending' || r['status'] == null).length;
                    int inReview = myReports.where((r) => r['status'] == 'in_review' || r['status'] == 'in review').length;
                    int resolved = myReports.where((r) => r['status'] == 'resolved').length;

                    // Take only the top 3 for the recent list
                    final recentReports = myReports.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.8,
                          children: [
                            _buildStatCard("My Reports", total.toString(), Icons.description, Colors.purple),
                            _buildStatCard("Pending", pending.toString(), Icons.error_outline, Colors.orange),
                            _buildStatCard("In Progress", inReview.toString(), Icons.access_time, Colors.blue),
                            _buildStatCard("Resolved", resolved.toString(), Icons.check_circle_outline, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _goToReportScreen,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.blue[800]!.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(Icons.add_circle, color: Colors.blue[800], size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Report New Grievance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Found an issue? Let us know.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildSectionHeader("Your Recent Reports", onTapViewAll: _goToHistory),
                        const SizedBox(height: 10),

                        recentReports.isEmpty
                            ? _buildEmptyState("You have no recent reports.")
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentReports.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(recentReports[index], isCommunity: false);
                          },
                        ),
                      ],
                    );
                  }
              ),

              const SizedBox(height: 30),

              // --- COMMUNITY SECTION ---
              _buildSectionHeader("Community Discussions", onTapViewAll: _goToCommunity),
              const SizedBox(height: 10),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: communityStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
                  final reports = snapshot.data!;

                  if (reports.isEmpty) return _buildEmptyState("No active discussions.");

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(reports[index], isCommunity: true);
                    },
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTapViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        TextButton(onPressed: onTapViewAll, child: const Text("View All")),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, {required bool isCommunity}) {
    final status = report['status'] ?? 'pending';
    final title = report['title'] ?? 'No Title';
    final date = report['created_at'].toString().split('T')[0];
    final color = _getStatusColor(status);

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
        side: BorderSide(color: isCommunity ? Colors.grey.shade200 : color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        onTap: () => _goToDetails(report),
        leading: CircleAvatar(
          backgroundColor: isCommunity ? Colors.blue.withOpacity(0.1) : color.withOpacity(0.1),
          child: Icon(
              isCommunity ? (isPrivate ? Icons.visibility_off : Icons.forum_outlined) : Icons.assignment,
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
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}