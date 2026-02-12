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
        .eq('user_id', userId) // <--- THIS LINE WAS MISSING
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Report History'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No history found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withOpacity(0.5)),
                ),
                child: ListTile(
                  onTap: () => _goToDetails(context, report),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$location • $date"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
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