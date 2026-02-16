import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  String? selectedAreaType;
  String? selectedSpecificLocation;

  bool isPrivate = false;
  bool _isLoading = false;

  final Map<String, List<String>> locationHierarchy = {
    'Academic Zone': ['Academic Block 1', 'Academic Block 2', 'Academic Block 3', 'Academic Block 4'],
    'Hostels': ['A Block Hostel', 'B Block Hostel', 'C Block Hostel', 'D1 Block Hostel', 'D2 Block Hostel'],
    'Common Areas': ['Library', 'Admin Block', 'North Square', 'Gazebo', 'Sports Ground', 'Canteen', 'Main Gate'],
  };

  // Your original categories
  final List<String> categories = [
    'Electrical',
    'Plumbing',
    'Furniture',
    'Cleanliness',
    'Wifi/Network',
    'Other'
  ];

  Future<void> _submitReport() async {
    if (titleController.text.isEmpty ||
        selectedCategory == null ||
        selectedSpecificLocation == null ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser!;

      await Supabase.instance.client.from('grievances').insert({
        'user_id': user.id,
        'user_email': user.email,
        'title': titleController.text.trim(),
        'category': selectedCategory,
        'location': selectedSpecificLocation,
        'description': descriptionController.text.trim(),
        'privacy': isPrivate ? 'private' : 'public',
        'status': 'pending',
        'progress': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance Reported Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- REDESIGNED DROPDOWN TO MATCH DASHBOARD STYLE ---
  Widget _buildStyledDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12), // Adjusted to match dashboard cards
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: enabled ? Colors.blue[800] : Colors.grey, size: 22),
              const SizedBox(width: 12),
              Text(
                hint,
                style: TextStyle(color: enabled ? Colors.grey[800] : Colors.grey, fontSize: 16),
              ),
            ],
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: enabled ? Colors.blue[800] : Colors.grey),
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Grievance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800], // Darker blue to match dashboard
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // Match dashboard background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Fill in the details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text('We will get this sorted for you.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 30),

            // --- TITLE FIELD ---
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Short Title',
                hintText: 'e.g., Broken Fan',
                prefixIcon: Icon(Icons.title, color: Colors.blue[800]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // --- DROPDOWNS ---
            _buildStyledDropdown(
              value: selectedCategory,
              hint: "Select Category",
              icon: Icons.category_outlined,
              items: categories,
              onChanged: (val) => setState(() => selectedCategory = val),
            ),

            _buildStyledDropdown(
              value: selectedAreaType,
              hint: "Select Area Type",
              icon: Icons.map_outlined,
              items: locationHierarchy.keys.toList(),
              onChanged: (val) {
                setState(() {
                  selectedAreaType = val;
                  selectedSpecificLocation = null;
                });
              },
            ),

            _buildStyledDropdown(
              value: selectedSpecificLocation,
              hint: selectedAreaType == null ? "Select Area Type first" : "Select Block/Building",
              icon: Icons.location_on_outlined,
              enabled: selectedAreaType != null,
              items: selectedAreaType == null ? [] : locationHierarchy[selectedAreaType]!,
              onChanged: (val) => setState(() => selectedSpecificLocation = val),
            ),

            // --- DESCRIPTION FIELD ---
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the issue in detail...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined, color: Colors.blue[800]),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // --- PRIVATE REPORT TOGGLE ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('Private Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('Only admins will see this.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                value: isPrivate,
                activeColor: Colors.blue[800],
                activeTrackColor: Colors.blue[800]!.withOpacity(0.3),
                secondary: Icon(isPrivate ? Icons.lock : Icons.lock_open, color: isPrivate ? Colors.blue[800] : Colors.grey),
                onChanged: (val) => setState(() => isPrivate = val),
              ),
            ),
            const SizedBox(height: 30),

            // --- SUBMIT BUTTON ---
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                elevation: 0, // Flat look to match the new theme
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SUBMIT REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}