import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/profile_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final int userId;

  const UpdateProfileScreen({super.key, required this.userId});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  String address = '';
  String? profilePicUrl;
  File? _pickedImage;
  bool isLoading = false;
  String errorText = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      isLoading = true;
    });
    try {
      final info = await ProfileService().getUserInfo(widget.userId);
      setState(() {
        _nameController.text = info['name'] ?? '';
        _streetController.text = info['street'] ?? '';
        address = info['address'] ?? '';
        profilePicUrl = info['profile_pic_url'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorText = 'Failed to load user info.';
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    String? uploadedImageUrl = profilePicUrl;
    if (_pickedImage != null) {
      uploadedImageUrl = await ProfileService().uploadProfilePicture(widget.userId, _pickedImage!.path);
      if (uploadedImageUrl == null) {
        setState(() {
          errorText = 'Failed to upload profile photo.';
          isLoading = false;
        });
        return;
      }
    }

    final success = await ProfileService().updateUserProfile(
      userId: widget.userId,
      name: _nameController.text,
      address: address,
      profilePicUrl: uploadedImageUrl,
    );
    setState(() {
      isLoading = false;
      if (success) {
        Navigator.pop(context, true); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        errorText = 'Failed to update profile.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _pickedImage != null
        ? CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(_pickedImage!),
          )
        : (profilePicUrl != null && profilePicUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profilePicUrl!),
              )
            : const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile picture.png'),
              ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: const Color(0xFF328E6E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile photo
                    Stack(
                      children: [
                        imageWidget,
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _streetController,
                      decoration: const InputDecoration(labelText: 'Street'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: address,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (errorText.isNotEmpty)
                      Text(errorText, style: const TextStyle(color: Colors.red)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF328E6E),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}