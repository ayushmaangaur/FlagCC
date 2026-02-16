import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const AdminReportDetailScreen({super.key, required this.report});

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;
  bool _isUpdating = false;

  late String _currentStatus;
  late double _currentProgress;
  late String _reportId;

  @override
  void initState() {
    super.initState();
    _reportId = widget.report['id'].toString();

    // Initialize Status
    String rawStatus = widget.report['status'] ?? 'pending';
    if (rawStatus == 'in_review' || rawStatus == 'in review') {
      _currentStatus = 'In Review';
    } else {
      _currentStatus = rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
    }

    // Catch-all for weird status strings
    if (!['Pending', 'In Review', 'Resolved', 'Closed', 'Rejected'].contains(_currentStatus)) {
      _currentStatus = 'Pending';
    }

    // Initialize Progress
    _currentProgress = (widget.report['progress'] ?? 0).toDouble();
  }

  // --- SAVE ADMIN CHANGES (STATUS & PROGRESS) ---
  Future<void> _saveAdminChanges() async {
    setState(() => _isUpdating = true);
    try {
      String dbStatus = _currentStatus.toLowerCase().replaceAll(' ', '_');

      await Supabase.instance.client.from('grievances').update({
        'status': dbStatus,
        'progress': _currentProgress.toInt(),
      }).eq('id', _reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- POST ADMIN COMMENT ---
  Future<void> _postComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser!;

      await Supabase.instance.client.from('comments').insert({
        'grievance_id': _reportId,
        'user_id': user.id,
        'user_email': user.email,
        'user_role': 'admin', // Flagged as admin
        'message': message,
        'is_anonymous': false
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
    final String title = report['title'] ?? 'No Title';
    final String description = report['description'] ?? 'No Description.';
    final String location = report['location'] ?? 'Unknown';
    final String category = report['category'] ?? 'General';
    final String email = report['user_email'] ?? 'Unknown User';

    String date = 'Unknown Date';
    if (report['created_at'] != null) {
      try { date = report['created_at'].toString().split('T')[0]; } catch (_) {}
    }

    final commentStream = Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('grievance_id', _reportId)
        .order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Report View'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. HEADER DETAILS ---
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Reported by: $email", style: TextStyle(color: Colors.grey[700])),
                  Text("Location: $location  •  Category: $category  •  Date: $date", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),

                  // --- 2. ADMIN CONTROL PANEL ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Admin Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const Divider(height: 24),

                        // Status Dropdown
                        const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _currentStatus,
                              items: ['Pending', 'In Review', 'Resolved', 'Closed', 'Rejected']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) => setState(() => _currentStatus = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Progress Slider
                        Text("Update Progress: ${_currentProgress.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _currentProgress,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: Colors.blue[900],
                          label: '${_currentProgress.round()}%',
                          onChanged: (val) => setState(() => _currentProgress = val),
                        ),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : _saveAdminChanges,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                            child: _isUpdating
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("SAVE CHANGES"),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 3. DESCRIPTION ---
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  ),
                  const SizedBox(height: 40),

                  // --- 4. DISCUSSION THREAD ---
                  const Text("Discussion", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: commentStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final comments = snapshot.data!;
                      if (comments.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No comments yet."));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          final bool isAnon = c['is_anonymous'] ?? false;
                          final String msg = c['message']?.toString() ?? '';
                          final String role = c['user_role']?.toString() ?? 'student';
                          final String userEmail = c['user_email']?.toString() ?? 'User';

                          String displayName = userEmail.split('@')[0];
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
                                  radius: 16,
                                  backgroundColor: role == 'admin' ? Colors.blue[900] : (isAnon ? Colors.grey[300] : Colors.orangeAccent),
                                  child: Icon(role == 'admin' ? Icons.support_agent : Icons.person, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.blue[900] : Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text(msg, style: const TextStyle(fontSize: 14)),
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
                ],
              ),
            ),
          ),

          // --- 5. ADMIN REPLY BOX ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Reply as Admin...",
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
                  backgroundColor: Colors.blue[900],
                  child: _isPosting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}