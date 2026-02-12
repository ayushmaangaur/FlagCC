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

  // --- 1. SAFE DATA HELPERS ---

  // FIX: Helper to get ID as String (Works for both UUID and Int)
  String _safeId(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

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
      case 'in_review': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'closed': return Colors.grey;
      case 'pending':
      default: return Colors.orange;
    }
  }

  // --- 2. POST COMMENT FUNCTION ---
  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser!;

      // FIX: Use the String ID directly
      final reportId = widget.report['id'];

      await Supabase.instance.client.from('comments').insert({
        'grievance_id': reportId,    // Send UUID string directly
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
        print("Post Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to post: $e'),
              backgroundColor: Colors.red
          ),
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
    final String description = _safeString(report['description'], 'No Description.');
    final String location = _safeString(report['location'], 'Unknown');
    final String category = _safeString(report['category'], 'General');
    final String status = _safeString(report['status'], 'Pending');
    final int progress = _safeInt(report['progress']);

    // FIX: Get Report ID as-is (Dynamic)
    final dynamic reportId = report['id'];

    String date = 'Unknown Date';
    if (report['created_at'] != null) {
      try {
        date = report['created_at'].toString().split('T')[0];
      } catch (_) {}
    }

    final statusColor = _getStatusColor(status);

    // FIX: Stream Filter
    final commentStream = Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('grievance_id', reportId) // This will now pass the correct UUID
        .order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report & Discussion'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- PROGRESS ---
                  Text("Progress: $progress%", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 20),

                  // --- INFO TILES ---
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.location_on, "Location", location)),
                      Expanded(child: _buildInfoTile(Icons.category, "Category", category)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(Icons.calendar_today, "Date", date),

                  const Divider(height: 40),

                  // --- DESCRIPTION ---
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  ),

                  const SizedBox(height: 40),

                  // --- DISCUSSION HEADER ---
                  const Row(
                    children: [
                      Icon(Icons.forum_outlined, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text("Community Discussion", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- COMMENTS LIST ---
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: commentStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text("No comments yet.\nStart the discussion!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];

                          // Safe Data Extraction
                          final bool isAnon = c['is_anonymous'] ?? false;
                          final String msg = _safeString(c['message'], '');
                          final String role = _safeString(c['user_role'], 'student');
                          final String email = _safeString(c['user_email'], 'User');

                          // Display Logic
                          String displayName = email.split('@')[0];
                          if (isAnon) displayName = "Anonymous Student";
                          if (role == 'admin') displayName = "Admin Support";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: role == 'admin' ? Colors.blue[50] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isAnon ? Colors.grey[300] : (role == 'admin' ? Colors.blueAccent : Colors.orangeAccent),
                                  child: Icon(
                                    isAnon ? Icons.person_off : (role == 'admin' ? Icons.support_agent : Icons.person),
                                    size: 20, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.blue[800] : Colors.black87)),
                                          if (role == 'admin') ...[
                                            const SizedBox(width: 5),
                                            const Icon(Icons.verified, size: 14, color: Colors.blue)
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(msg, style: const TextStyle(fontSize: 14, color: Colors.black87)),
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

          // --- INPUT BOX ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(height: 24, width: 24, child: Checkbox(value: _isAnonymous, activeColor: Colors.blueAccent, onChanged: (val) => setState(() => _isAnonymous = val!))),
                    const SizedBox(width: 8),
                    Text("Post Anonymously", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton.small(
                      onPressed: _isPosting ? null : _postComment,
                      backgroundColor: Colors.blueAccent,
                      child: _isPosting ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}