import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const StudentReportDetailScreen({super.key, required this.report});

  @override
  State<StudentReportDetailScreen> createState() => _StudentReportDetailScreenState();
}

class _StudentReportDetailScreenState extends State<StudentReportDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isPosting = false;

  // --- SAFE DATA HELPERS ---
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _safeString(dynamic value, String fallback) {
    return value?.toString() ?? fallback;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in_review':
      case 'in review': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'closed': return Colors.grey;
      case 'pending':
      default: return Colors.orange;
    }
  }

  // --- POST COMMENT FUNCTION ---
  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final reportId = widget.report['id'].toString(); // Forces String to prevent UUID errors

      await Supabase.instance.client.from('comments').insert({
        'grievance_id': reportId,
        'user_id': user.id,
        'user_email': user.email,
        'user_role': 'student',
        'message': message,
        'is_anonymous': _isAnonymous
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final String title = _safeString(report['title'], 'No Title');
    final String description = _safeString(report['description'], 'No Description provided.');
    final String location = _safeString(report['location'], 'Unknown');
    final String category = _safeString(report['category'], 'General');
    final String status = _safeString(report['status'], 'Pending');
    final int progress = _safeInt(report['progress']);

    final String reportIdStr = report['id'].toString();

    // Parse Date
    String date = 'Unknown Date';
    if (report['created_at'] != null) {
      try {
        date = report['created_at'].toString().split('T')[0];
      } catch (_) {}
    }

    final statusColor = _getStatusColor(status);

    // Stream Comments
    final commentStream = Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('grievance_id', reportIdStr)
        .order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match dashboard background
      appBar: AppBar(
        title: const Text('Report & Discussion', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800], // Match dashboard app bar
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SCROLLABLE CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progress", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                      Text("$progress%", style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      color: statusColor,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Info Grid
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.location_on_outlined, "Location", location)),
                      Expanded(child: _buildInfoTile(Icons.category_outlined, "Category", category)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(Icons.calendar_today_outlined, "Date", date),

                  const Divider(height: 40, color: Colors.black12),

                  // 4. Description Box
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(description, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800])),
                  ),

                  const SizedBox(height: 40),

                  // 5. Discussion Header
                  Row(
                    children: [
                      Icon(Icons.forum_outlined, color: Colors.blue[800]),
                      const SizedBox(width: 10),
                      const Text("Community Discussion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. COMMENTS LIST
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: commentStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('Error loading comments: ${snapshot.error}');
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text("No comments yet.\nStart the discussion!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];

                          final bool isAnon = c['is_anonymous'] ?? false;
                          final String msg = _safeString(c['message'], '');
                          final String role = _safeString(c['user_role'], 'student');
                          final String email = _safeString(c['user_email'], 'User');

                          String displayName = email.split('@')[0];
                          if (isAnon) displayName = "Anonymous Student";
                          if (role == 'admin') displayName = "Admin Support";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: role == 'admin' ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: role == 'admin' ? Colors.blue.shade200 : Colors.grey.shade300),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: role == 'admin' ? Colors.blue[800] : (isAnon ? Colors.grey[400] : Colors.orangeAccent),
                                  child: Icon(
                                    role == 'admin' ? Icons.support_agent : (isAnon ? Icons.person_off : Icons.person),
                                    size: 20, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              displayName,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: role == 'admin' ? Colors.blue[900] : Colors.black87)
                                          ),
                                          if (role == 'admin') ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.verified, size: 14, color: Colors.blue[800])
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(msg, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // --- COMMENT INPUT BOX ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)), // Flat border instead of shadow
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                              value: _isAnonymous,
                              activeColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _isAnonymous = val!)
                          )
                      ),
                      const SizedBox(width: 8),
                      Text("Post Anonymously", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        onPressed: _isPosting ? null : _postComment,
                        backgroundColor: Colors.blue[800], // Match theme
                        elevation: 0,
                        child: _isPosting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGET ---
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[800], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}