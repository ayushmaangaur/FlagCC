import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_detail_screen.dart';

class StudentHistoryScreen extends StatelessWidget {
  const StudentHistoryScreen({super.key});

  void _goToDetails(BuildContext context, Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReportDetailScreen(report: report),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in_review':
      case 'in review': return Colors.blue;
      case 'closed': return Colors.grey;
      case 'rejected': return Colors.red;
      case 'pending':
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Icons.check_circle;
      case 'in_review':
      case 'in review': return Icons.sync;
      case 'closed': return Icons.archive;
      case 'rejected': return Icons.cancel;
      case 'pending':
      default: return Icons.access_time_filled;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET CURRENT USER ID
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // 2. FILTER STREAM BY USER ID
    final _grievanceStream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match the clean dashboard background
      appBar: AppBar(
        title: const Text('My Report History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800], // Deep blue to match the new theme
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _grievanceStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No history found.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final status = report['status'] ?? 'pending';
              final title = report['title'] ?? 'No Title';
              final date = report['created_at'] != null
                  ? report['created_at'].toString().split('T')[0]
                  : 'Unknown Date';
              final location = report['location'] ?? 'Unknown Location';

              final color = _getStatusColor(status);
              final icon = _getStatusIcon(status);

              // --- NEW FLAT CARD DESIGN ---
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1), // Crisp grey border
                ),
                child: InkWell(
                  onTap: () => _goToDetails(context, report),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 16),

                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  "$location • $date",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                              status.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}