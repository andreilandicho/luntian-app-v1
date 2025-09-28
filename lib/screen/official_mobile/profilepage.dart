import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/screen/user/login_screen.dart';
import 'package:flutter_application_1/models/user_official_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/barangay_service.dart';
import 'package:flutter_application_1/services/official_profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedIndex = 3; // Profile tab index
  bool isNavVisible = true;


  UserOfficialModel? official;
  String barangayName = '';
  String barangayCity = '';
  bool isLoading = true;
  String? profilePicUrl; // URL from official data

  @override
  void initState() {
    super.initState();
    _loadOfficialData();
  }

  Future<void> _loadOfficialData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('official_data');
    if (dataString != null) {
      final data = jsonDecode(dataString);
      final loadedOfficial = UserOfficialModel.fromJson(data);
      setState(() {
        official = loadedOfficial;
        profilePicUrl = loadedOfficial.officialProfileUrl;
      });
      // Fetch barangay info
      final barangayInfo = await BarangayService().getBarangayInfo(loadedOfficial.officialBarangayId);
      if (barangayInfo != null) {
        setState(() {
          barangayName = barangayInfo['barangay_name'] ?? '';
          barangayCity = barangayInfo['barangay_municipality'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // No official_data found, stop loading and optionally navigate to login
      setState(() {
        isLoading = false;
        official = null;
      });
      // Optionally, navigate to login automatically:
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      });
    }
  }
  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && official != null) {
      setState(() => isLoading = true);
      final url = await OfficialProfileService().uploadProfilePhoto(
        official!.officialUserId,
        pickedFile.path,
      );
      if (url != null) {
        setState(() {
          profilePicUrl = url;
          isLoading = false;
        });
        // Update SharedPreferences as well
        final prefs = await SharedPreferences.getInstance();
        final dataString = prefs.getString('official_data');
        if (dataString != null) {
          final data = jsonDecode(dataString);
          data['user_profile_url'] = url;
          await prefs.setString('official_data', jsonEncode(data));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile photo.')),
        );
      }
    }
  }
  
  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('official_data');

              // Close the dialog first
              Navigator.of(dialogContext).pop();

              if (!mounted) return;

              // Now navigate and clear stack
              Future.microtask(() {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
                print('Navigated to LoginPage');
              });
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : official == null
              ? const Center(child: Text('You are not logged in.No official data found.'))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile picture with edit
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                              ? NetworkImage(profilePicUrl!)
                              : const AssetImage('assets/profile picture.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changeProfilePicture,
                            child: const CircleAvatar(
                              radius: 16,
                        backgroundColor: Colors.white,
                              child: Icon(Icons.edit, size: 18, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name & Location
                    Text(
                      official!.officialName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$barangayName, $barangayCity',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      official!.officialEmail,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _logout,
                        child: const Text('Log Out', style: TextStyle(fontSize: 16)),
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