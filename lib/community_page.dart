import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_detail_screen.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {

  // --- NAVIGATION ---
  void _goToDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Stream fetching ALL grievances (we will filter for privacy in the builder)
    final stream = Supabase.instance.client
        .from('grievances')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match new clean background
      appBar: AppBar(
        title: const Text('Community Discussions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900], // Deep blue to match Login & Dashboard
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allReports = snapshot.data!;

          // Filter: Show all public reports OR reports that belong to the current user (even if private)
          final visibleReports = allReports.where((report) {
            final isPrivate = report['privacy'] == 'private';
            final ownerId = report['user_id'];
            return !isPrivate || ownerId == currentUserId;
          }).toList();

          if (visibleReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No active discussions.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: visibleReports.length,
            itemBuilder: (context, index) {
              final report = visibleReports[index];
              final title = report['title'] ?? 'No Title';
              final location = report['location'] ?? 'Unknown Location';

              String date = 'Unknown Date';
              if (report['created_at'] != null) {
                try {
                  date = report['created_at'].toString().split('T')[0];
                } catch (_) {}
              }

              final bool isPrivate = (report['privacy'] == 'private');
              final String reportUserId = report['user_id'];
              final String email = report['user_email'] ?? 'User';

              // Determine display name
              String postedBy;
              if (reportUserId == currentUserId) {
                postedBy = "Me ${isPrivate ? '(Private)' : ''}";
              } else if (isPrivate) {
                postedBy = "Anonymous Student";
              } else {
                postedBy = email.split('@')[0];
              }

              // --- NEW CARD DESIGN ---
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1), // Crisp grey border
                ),
                child: InkWell(
                  onTap: () => _goToDetails(report),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isPrivate ? Colors.grey[200] : Colors.blue[50],
                          child: Icon(
                              isPrivate ? Icons.visibility_off : Icons.forum,
                              color: isPrivate ? Colors.grey[600] : Colors.blue[900], // Deep blue for public icons
                              size: 20
                          ),
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
                                  "By $postedBy • $location",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Date
                        Text(
                            date,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)
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