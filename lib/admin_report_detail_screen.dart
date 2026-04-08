import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const AdminReportDetailScreen({super.key, required this.report});

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final TextEditingController _internalNoteController = TextEditingController();

  bool _isUpdating = false;
  late String _currentStatus;
  late double _currentProgress;
  late String _stringReportId;
  late bool _isPinged;

  @override
  void initState() {
    super.initState();
    _stringReportId = widget.report['id'].toString();
    _isPinged = widget.report['is_pinged'] == true;

    String rawStatus = widget.report['status'] ?? 'pending';
    if (rawStatus == 'in_review' || rawStatus == 'in review') {
      _currentStatus = 'In Review';
    } else {
      _currentStatus = rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
    }
    if (!['Pending', 'In Review', 'Resolved', 'Closed', 'Rejected'].contains(_currentStatus)) {
      _currentStatus = 'Pending';
    }
    _currentProgress = (widget.report['progress'] ?? 0).toDouble();
  }

  // --- ACKNOWLEDGE PING (BUG FIXED) ---
  Future<void> _acknowledgePing() async {
    try {
      await Supabase.instance.client.from('grievances')
          .update({'is_pinged': false})
          .eq('id', widget.report['id']);

      setState(() => _isPinged = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ping Acknowledged.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  // --- SAVE ADMIN CHANGES (BUG FIXED) ---
  Future<void> _saveAdminChanges() async {
    setState(() => _isUpdating = true);
    try {
      String dbStatus = _currentStatus.toLowerCase().replaceAll(' ', '_');
      await Supabase.instance.client.from('grievances')
          .update({'status': dbStatus, 'progress': _currentProgress.toInt()})
          .eq('id', widget.report['id']);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- POST INTERNAL NOTE ---
  Future<void> _postInternalNote() async {
    final message = _internalNoteController.text.trim();
    if (message.isEmpty) return;
    try {
      final email = Supabase.instance.client.auth.currentUser!.email;
      await Supabase.instance.client.from('internal_notes').insert({
        'grievance_id': _stringReportId,
        'sender_email': email,
        'message': message
      });
      _internalNoteController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post note: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final title = report['title'] ?? 'No Title';
    final desc = report['description'] ?? 'No Description.';

    final notesStream = Supabase.instance.client.from('internal_notes').stream(primaryKey: ['id']).eq('grievance_id', _stringReportId).order('created_at', ascending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Report'), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PING ALERT ---
            if (_isPinged)
              Container(
                margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("SUPERVISOR PING: Please action this item ASAP.", style: TextStyle(fontWeight: FontWeight.bold))),
                    ElevatedButton(onPressed: _acknowledgePing, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text("Clear", style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),

            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- ADMIN CONTROL PANEL ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200, width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, value: _currentStatus,
                        items: ['Pending', 'In Review', 'Resolved', 'Closed', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _currentStatus = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Update Progress: ${_currentProgress.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(value: _currentProgress, min: 0, max: 100, divisions: 100, activeColor: Colors.blue[900], label: '${_currentProgress.round()}%', onChanged: (val) => setState(() => _currentProgress = val)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _saveAdminChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                      child: _isUpdating ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("SAVE CHANGES"),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Text(desc, style: const TextStyle(fontSize: 16, height: 1.5))),
            const SizedBox(height: 40),

            // --- INTERNAL NOTES SECTION ---
            const Text("Internal Staff Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200, width: 2)),
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: notesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final notes = snapshot.data!;
                      if (notes.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 12), child: Text("No internal notes yet.", style: TextStyle(color: Colors.grey)));

                      return ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final isSupervisor = note['sender_email'].toString().contains('supervisor');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isSupervisor ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(note['sender_email'].toString().split('@')[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSupervisor ? Colors.orange[800] : Colors.blue[800])),
                                Text(note['message'].toString(), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _internalNoteController, decoration: const InputDecoration(hintText: "Reply to supervisor...", isDense: true))),
                      IconButton(icon: const Icon(Icons.send, color: Colors.orange), onPressed: _postInternalNote),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}