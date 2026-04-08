import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const SupervisorReportDetailScreen({super.key, required this.report});

  @override
  State<SupervisorReportDetailScreen> createState() => _SupervisorReportDetailScreenState();
}

class _SupervisorReportDetailScreenState extends State<SupervisorReportDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isPosting = false;
  late bool _isPinged;
  late String _stringReportId;

  @override
  void initState() {
    super.initState();
    // We keep a string version for the internal_notes table
    _stringReportId = widget.report['id'].toString();
    _isPinged = widget.report['is_pinged'] == true;
  }

  // --- PING DEPARTMENT (BUG FIXED) ---
  Future<void> _pingDepartment() async {
    try {
      // Passes the raw ID exactly as it came from the database
      await Supabase.instance.client.from('grievances')
          .update({'is_pinged': true})
          .eq('id', widget.report['id']);

      setState(() => _isPinged = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department Pinged Successfully!'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ping: $e'), backgroundColor: Colors.red));
    }
  }

  // --- POST INTERNAL NOTE ---
  Future<void> _postInternalNote() async {
    final message = _noteController.text.trim();
    if (message.isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final email = Supabase.instance.client.auth.currentUser!.email;
      await Supabase.instance.client.from('internal_notes').insert({
        'grievance_id': _stringReportId,
        'sender_email': email,
        'message': message,
      });
      _noteController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post note: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final title = report['title'] ?? 'No Title';
    final desc = report['description'] ?? 'No Description.';
    final category = report['category'] ?? 'General';
    final status = (report['status'] ?? 'pending').toString().toUpperCase().replaceAll('_', ' ');
    final progress = report['progress'] ?? 0;

    final notesStream = Supabase.instance.client.from('internal_notes').stream(primaryKey: ['id']).eq('grievance_id', _stringReportId).order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Supervisor View'), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SUPERVISOR CONTROLS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200, width: 2)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Supervisor Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                            Text("Send a priority alert to the dept.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isPinged ? null : _pingDepartment,
                          icon: Icon(Icons.notifications_active, color: _isPinged ? Colors.grey : Colors.white),
                          label: Text(_isPinged ? "PINGED" : "PING DEPT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPinged ? Colors.grey[300] : Colors.orange[700],
                            foregroundColor: _isPinged ? Colors.grey[600] : Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // REPORT DETAILS
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Category: $category • Status: $status • Progress: $progress%", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: Text(desc, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  const SizedBox(height: 30),

                  // INTERNAL NOTES THREAD
                  const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text("Internal Staff Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text("Visible only to Supervisors and Department Staff.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: notesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final notes = snapshot.data!;
                      if (notes.isEmpty) return const Text("No internal notes yet.", style: TextStyle(color: Colors.grey));

                      return ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final isSupervisor = note['sender_email'].toString().contains('supervisor');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: isSupervisor ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isSupervisor ? Colors.orange.shade200 : Colors.blue.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(note['sender_email'].toString().split('@')[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSupervisor ? Colors.orange[800] : Colors.blue[800])),
                                const SizedBox(height: 4),
                                Text(note['message'].toString(), style: const TextStyle(fontSize: 14)),
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

          // NOTE INPUT BOX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(hintText: "Add an internal note...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    onPressed: _isPosting ? null : _postInternalNote,
                    backgroundColor: Colors.orange[700], elevation: 0,
                    child: _isPosting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}