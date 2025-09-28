import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'official.dart'; // Import the official dashboard
import 'package:flutter_application_1/services/maintenance/solution_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProofReviewPage extends StatefulWidget {
  final List<String> imagePaths;
  final int reportId;
  const ProofReviewPage({super.key, required this.imagePaths, required this.reportId});

  @override
  State<ProofReviewPage> createState() => _ProofReviewPageState();
}

class _ProofReviewPageState extends State<ProofReviewPage> {
  int selectedIndex = 0;
  bool isNavVisible = true;

  final TextEditingController _descriptionController = TextEditingController();

  Future<int?> _getUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('official_data');
    if (dataString != null) {
      final data = jsonDecode(dataString);
      return data['user_id'] as int?;
    }
    return null;
  }

  Future<void> _submitSolution() async {
    final userId = await _getUserIdFromPrefs();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final cleanupNotes = _descriptionController.text.trim();
    if (cleanupNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add cleanup notes.')),
      );
      return;
    }

    final imageFiles = widget.imagePaths.map((path) => File(path)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await SolutionService.submitReportSolution(
      reportId: widget.reportId,
      userId: userId,
      imageFiles: imageFiles,
      cleanupNotes: cleanupNotes,
    );

    Navigator.of(context, rootNavigator: true).pop(); // Close loading

    if (success) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              "Solution Submitted",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Your solution has been submitted. Wait for the barangay's approval.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OfficialDashboard()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit solution.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      appBar: LuntianHeader(
        isSmallScreen: isSmallScreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REVIEW SOLUTION',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 450,
                child: ListView.builder(
                  itemCount: widget.imagePaths.length,
                  itemBuilder: (context, index) {
                    final path = widget.imagePaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          height: 450,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add cleanup notes...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitSolution,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text(
                    "Submit Solution",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF328E6E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LuntianFooter(
        selectedIndex: selectedIndex,
        isNavVisible: isNavVisible,
        isSmallScreen: isSmallScreen,
        onItemTapped: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}