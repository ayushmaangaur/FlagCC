import 'package:flutter/material.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  // 1. Variables to store user choices
  String? selectedLocation;
  String? selectedIssueType;
  final TextEditingController descriptionController = TextEditingController();

  // Data for the dropdowns
  final List<String> locations = [
    'Academic Block 1',
    'Academic Block 2',
    'Academic Block 3',
    'Academic Block 4'
    'Library',
    'Admin Block',
    'North Square',
    'Gazebo',
    'A Block Hostel',
    'B Block Hostel',
    'C Block Hostel',
    'D1 Block Hostel',
    'D2 Block Hostel',
    'Sports Ground',
  ];

  final List<String> issueTypes = [
    'Electrical (Switch/Fan/Light)',
    'Water/Plumbing',
    'Furniture/Broken Items',
    'Cleanliness/Hygiene',
    'Food Quality',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Grievance'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fill in the details below',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 2. Location Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              value: selectedLocation,
              items: locations.map((String loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // 3. Issue Type Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type of Problem',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
              value: selectedIssueType,
              items: issueTypes.map((String type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedIssueType = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // 4. Description Text Field
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the issue in detail...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // 5. Image Upload Placeholder (Visual Only for now)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: InkWell(
                onTap: () {
                  // TODO: Implement Camera/Gallery Logic later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Camera feature coming next!")),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 6. Submit Button
            ElevatedButton(
              onPressed: () {
                // For now, just print the data to console to test
                print("Location: $selectedLocation");
                print("Issue: $selectedIssueType");
                print("Desc: ${descriptionController.text}");
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'SUBMIT REPORT',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}