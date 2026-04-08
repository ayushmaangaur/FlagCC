import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_detail_screen.dart'; // Uses Student view for Read-Only access
import 'main.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  String _filterCategory = 'All Categories';
  String _filterStatus = 'All Status';

  final List<String> _categories = [
    'All Categories', 'Electrical', 'Plumbing', 'Furniture', 'Cleanliness', 'Wifi/Network', 'Other'
  ];

  final List<String> _statuses = [
    'All Status', 'Pending', 'In Review', 'Resolved', 'Closed', 'Rejected'
  ];

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to exit the management portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingScreen()), (route) => false);
      }
    }
  }

  // Uses async/await and setState to refresh the global list when returning
  Future<void> _viewDetailsReadOnly(Map<String, dynamic> report) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => StudentReportDetailScreen(report: report)));
    setState(() {});
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
    final directorEmail = Supabase.instance.client.auth.currentUser?.email ?? 'supervisor@vit.ac.in';

    // Stream fetches EVERYTHING. No department filter.
    final _stream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Director Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Supervising all departments', style: TextStyle(fontSize: 12, color: Colors.blue[100])),
          ],
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, size: 20), tooltip: 'Sign Out', onPressed: _signOut),
        ],
      ),

      // --- NEW: SIDEBAR (DRAWER) ADDED FOR SUPERVISOR ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[900]),
              accountName: const Text('SUPERVISOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
              accountEmail: Text(directorEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.shield, size: 40, color: Colors.blue), // Shield icon for Director
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.blue[900]),
              title: const Text('Global Overview'),
              selected: true,
              onTap: () {
                Navigator.pop(context); // Just closes the drawer
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

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allReports = snapshot.data!;

          int total = allReports.length;
          int pending = allReports.where((r) => r['status'] == 'pending' || r['status'] == null).length;
          int inReview = allReports.where((r) => r['status'] == 'in_review' || r['status'] == 'in review').length;
          int resolved = allReports.where((r) => r['status'] == 'resolved').length;

          List<Map<String, dynamic>> filteredReports = allReports.where((report) {
            final catMatches = _filterCategory == 'All Categories' || report['category'] == _filterCategory;
            String reportStatus = (report['status'] ?? 'pending').toString().toLowerCase().replaceAll('_', ' ');
            String filterStat = _filterStatus.toLowerCase().replaceAll('_', ' ');
            final statMatches = _filterStatus == 'All Status' || reportStatus == filterStat;
            return catMatches && statMatches;
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                          _buildStatCard("Total Campus Reports", total.toString(), Icons.assessment, Colors.purple),
                          _buildStatCard("Pending Action", pending.toString(), Icons.error_outline, Colors.orange),
                          _buildStatCard("Currently In Progress", inReview.toString(), Icons.engineering, Colors.blue),
                          _buildStatCard("Successfully Resolved", resolved.toString(), Icons.check_circle, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt_outlined, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterCategory,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) => setState(() => _filterCategory = val!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterStatus,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) => setState(() => _filterStatus = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Global Grievance Feed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final report = filteredReports[index];
                      final title = report['title'] ?? 'No Title';
                      final category = report['category'] ?? 'Other';
                      final rawStatus = report['status'] ?? 'pending';
                      final displayStatus = rawStatus.toString().toUpperCase().replaceAll('_', ' ');
                      final color = _getStatusColor(rawStatus);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                        child: ListTile(
                          onTap: () => _viewDetailsReadOnly(report),
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Dept: $category", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text(displayStatus, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                    childCount: filteredReports.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: color)
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}