import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_report_detail_screen.dart';
import 'department_selection_screen.dart';
import 'main.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String department;
  const AdminDashboardScreen({super.key, required this.department});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _filterStatus = 'All Status';

  final List<String> _statuses = ['All Status', 'Pending', 'In Review', 'Resolved', 'Closed', 'Rejected'];

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingScreen()), (route) => false);
    }
  }

  Future<void> _goToAdminDetails(Map<String, dynamic> report) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => AdminReportDetailScreen(report: report)));
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
    final adminEmail = Supabase.instance.client.auth.currentUser?.email ?? 'staff@vit.ac.in';

    final _stream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .eq('category', widget.department)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.department} Dept.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Manage departmental grievances', style: TextStyle(fontSize: 12, color: Colors.blue[100])),
          ],
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 18),
                  const SizedBox(width: 6),
                  Text(adminEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
              decoration: BoxDecoration(color: Colors.blue[900]),
              accountName: Text('${widget.department} Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(adminEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.engineering, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.blue[900]),
              title: const Text('Department Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: Colors.blue[900]),
              title: const Text('Change Department'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DepartmentSelectionScreen()),
                );
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
            String reportStatus = (report['status'] ?? 'pending').toString().toLowerCase().replaceAll('_', ' ');
            String filterStat = _filterStatus.toLowerCase().replaceAll('_', ' ');
            return _filterStatus == 'All Status' || reportStatus == filterStat;
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
                          _buildStatCard("Total", total.toString(), Icons.description, Colors.purple),
                          _buildStatCard("Pending", pending.toString(), Icons.error_outline, Colors.orange),
                          _buildStatCard("In Progress", inReview.toString(), Icons.access_time, Colors.blue),
                          _buildStatCard("Resolved", resolved.toString(), Icons.check_circle_outline, Colors.green),
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
                            const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterStatus,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) => setState(() => _filterStatus = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Active Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                      final desc = report['description'] ?? 'No description';
                      final email = report['user_email'] ?? 'Unknown User';
                      final date = report['created_at'] != null ? report['created_at'].toString().split('T')[0] : 'Unknown';
                      final rawStatus = report['status'] ?? 'pending';
                      final displayStatus = rawStatus.toString().toUpperCase().replaceAll('_', ' ');
                      final color = _getStatusColor(rawStatus);

                      // --- HIGHLIGHT IF PINGED ---
                      final isPinged = report['is_pinged'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isPinged ? Colors.orange[50] : Colors.white, // Highlight if pinged
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isPinged ? Colors.orange : Colors.grey.shade300, width: isPinged ? 2 : 1)
                        ),
                        child: InkWell(
                          onTap: () => _goToAdminDetails(report),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isPinged) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20)),
                                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                      child: Text(displayStatus, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("By: ${email.split('@')[0]}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ],
                            ),
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
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}