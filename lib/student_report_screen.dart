import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;

  // 2. Lists to hold data fetched from Supabase
  List<String> locations = [];
  List<String> issueTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownOptions(); // Fetch real data on load
  }

  // --- FETCH OPTIONS FROM SUPABASE ---
  Future<void> _fetchDropdownOptions() async {
    try {
      // NOTE: Once you have dashboard access, check if these table names
      // are 'locations' vs 'Locations' and 'issue_types' vs 'issueTypes'

      // Fetch locations
      final locData = await Supabase.instance.client
          .from('locations') // <--- Verify this name in Dashboard
          .select('name')
          .order('name', ascending: true);

      // Fetch issue types
      final typeData = await Supabase.instance.client
          .from('issue_types') // <--- Verify this name in Dashboard
          .select('name')
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          locations = List<String>.from(locData.map((e) => e['name']));
          issueTypes = List<String>.from(typeData.map((e) => e['name']));
        });
      }
    } catch (e) {
      if (mounted) {
        // If this prints "PGRST205", the table name is wrong or RLS is blocking it
        print("Error fetching options: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load options. Check Admin Dashboard.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- SUBMIT REPORT FUNCTION ---
  Future<void> _submitReport() async {
    if (selectedLocation == null ||
        selectedIssueType == null ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // INSERT into 'grievances' table
      await Supabase.instance.client.from('grievances').insert({
        'user_id': userId,
        'location': selectedLocation,
        'issue_type': selectedIssueType,
        'description': descriptionController.text.trim(),
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Submitted Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Grievance'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fill in the details below',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 1. LOCATION DROPDOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              value: selectedLocation,
              hint: const Text("Select Location"),
              // If list is empty (fetch failed), show nothing
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

            // 2. ISSUE TYPE DROPDOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type of Problem',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
              value: selectedIssueType,
              hint: const Text("Select Issue Type"),
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

            // 3. DESCRIPTION
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
            const SizedBox(height: 30),

            // 4. SUBMIT BUTTON
            ElevatedButton(
              onPressed: _submitReport,
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