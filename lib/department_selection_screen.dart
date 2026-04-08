import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard_screen.dart';
import 'main.dart';

class DepartmentSelectionScreen extends StatelessWidget {
  const DepartmentSelectionScreen({super.key});

  final List<Map<String, dynamic>> _departments = const [
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Furniture', 'icon': Icons.chair_alt},
    {'name': 'Cleanliness', 'icon': Icons.cleaning_services},
    {'name': 'Wifi/Network', 'icon': Icons.wifi},
    {'name': 'Other', 'icon': Icons.category},
  ];

  void _selectDepartment(BuildContext context, String departmentName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboardScreen(department: departmentName)),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Department', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _signOut(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, Staff", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            const SizedBox(height: 8),
            Text("Please select your department to view relevant grievances.", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final dept = _departments[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () => _selectDepartment(context, dept['name']),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(dept['icon'], size: 40, color: Colors.blue[800]),
                          const SizedBox(height: 12),
                          Text(dept['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}