import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  // --- Controllers ---
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // --- State Variables ---
  String? selectedCategory;
  String? selectedAreaType;
  String? selectedSpecificLocation;

  bool isPrivate = false;
  bool _isLoading = false;

  // --- HIERARCHICAL DATA ---
  final Map<String, List<String>> locationHierarchy = {
    'Academic Zone': ['Academic Block 1', 'Academic Block 2', 'Academic Block 3', 'Academic Block 4'],
    'Hostels': ['A Block Hostel', 'B Block Hostel', 'C Block Hostel', 'D1 Block Hostel', 'D2 Block Hostel'],
    'Common Areas': ['Library', 'Admin Block', 'North Square', 'Gazebo', 'Sports Ground', 'Canteen', 'Main Gate'],
  };

  final List<String> categories = ['Electrical', 'Plumbing', 'Furniture', 'Cleanliness', 'Wifi/Network', 'Other'];

  // --- SUBMIT FUNCTION ---
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

  // --- CUSTOM UI BUILDER FOR DROPDOWNS ---
  // This makes the dropdowns look like modern cards instead of simple lines
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
        color: enabled ? Colors.white : Colors.grey[100], // Grey out if disabled
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          if (enabled) // Only show shadow if enabled
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
        border: Border.all(
          color: enabled ? Colors.blueAccent.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: enabled ? Colors.blueAccent : Colors.grey, size: 22),
              const SizedBox(width: 12),
              Text(
                hint,
                style: TextStyle(
                  color: enabled ? Colors.grey[800] : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          icon: Icon(Icons.arrow_drop_down_circle, color: enabled ? Colors.blueAccent : Colors.grey),
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  // Small dot indicator for list items
                  Icon(Icons.circle, size: 8, color: Colors.blueAccent.withOpacity(0.6)),
                  const SizedBox(width: 12),
                  Text(item),
                ],
              ),
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
        title: const Text('New Grievance'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // Very light background to make cards pop
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'Fill in the details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 5),
            Text(
                'We will get this sorted for you.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])
            ),
            const SizedBox(height: 30),

            // 1. TITLE INPUT
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Short Title',
                hintText: 'e.g., Broken Fan',
                prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 2. CATEGORY DROPDOWN
            _buildStyledDropdown(
              value: selectedCategory,
              hint: "Select Category",
              icon: Icons.category_outlined,
              items: categories,
              onChanged: (val) => setState(() => selectedCategory = val),
            ),

            // 3. AREA TYPE DROPDOWN
            _buildStyledDropdown(
              value: selectedAreaType,
              hint: "Select Area Type",
              icon: Icons.map_outlined,
              items: locationHierarchy.keys.toList(),
              onChanged: (val) {
                setState(() {
                  selectedAreaType = val;
                  selectedSpecificLocation = null; // Reset child
                });
              },
            ),

            // 4. SPECIFIC LOCATION DROPDOWN (Cascading)
            _buildStyledDropdown(
              value: selectedSpecificLocation,
              hint: selectedAreaType == null ? "Select Area Type first" : "Select Block/Building",
              icon: Icons.location_on_outlined,
              enabled: selectedAreaType != null,
              items: selectedAreaType == null ? [] : locationHierarchy[selectedAreaType]!,
              onChanged: (val) => setState(() => selectedSpecificLocation = val),
            ),

            // 5. DESCRIPTION INPUT
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the issue in detail...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60), // Align icon to top
                  child: Icon(Icons.description_outlined, color: Colors.blueAccent),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 6. PRIVACY SWITCH
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: SwitchListTile(
                title: const Text('Private Report', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Enable anonymous identity.', style: TextStyle(fontSize: 12)),
                value: isPrivate,
                activeColor: Colors.blueAccent,
                secondary: Icon(isPrivate ? Icons.lock : Icons.lock_open, color: Colors.blueAccent),
                onChanged: (val) => setState(() => isPrivate = val),
              ),
            ),
            const SizedBox(height: 30),

            // 7. SUBMIT BUTTON
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.blueAccent.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('SUBMIT REPORT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}