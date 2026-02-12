import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_detail_screen.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  void _goToDetails(BuildContext context, Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Stream: Fetch ALL grievances (Removed privacy filter)
    final _stream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Discussions'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final reports = snapshot.data!;

          if (reports.isEmpty) {
            return const Center(child: Text("No community activity yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              // Formatting
              final title = report['title'] ?? 'No Title';
              final location = report['location'] ?? 'Unknown';
              final date = report['created_at'].toString().split('T')[0];

              // --- ANONYMITY LOGIC ---
              final bool isPrivate = (report['privacy'] == 'private');
              final String email = report['user_email'] as String? ?? 'Anonymous';
              final String userId = report['user_id'] as String? ?? '';

              String postedBy;

              if (userId == currentUserId) {
                // Always show "Me" for my own posts (even if private)
                postedBy = "Me ${isPrivate ? '(Private)' : ''}";
              } else if (isPrivate) {
                // Hide name for others if private
                postedBy = "Anonymous Student";
              } else {
                // Show name if public
                postedBy = email.split('@')[0];
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => _goToDetails(context, report),
                  leading: CircleAvatar(
                    backgroundColor: isPrivate ? Colors.grey[300] : Colors.blueAccent.withOpacity(0.1),
                    child: Icon(
                        isPrivate ? Icons.visibility_off : Icons.forum,
                        color: isPrivate ? Colors.grey[600] : Colors.blueAccent
                    ),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("By $postedBy • $location"),
                  trailing: Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}