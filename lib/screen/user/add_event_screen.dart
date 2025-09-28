import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

final supabase = Supabase.instance.client;

class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEvent;

  const AddEventScreen({super.key, this.existingEvent});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final ImagePicker picker = ImagePicker();
  final List<File> _selectedImages = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController volunteersController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? dateTime;
  bool? isPublic = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    
    if (widget.existingEvent != null) {
      titleController.text = widget.existingEvent!['title'] ?? '';
      volunteersController.text = widget.existingEvent!['volunteers_needed']?.toString() ?? '';
      descriptionController.text = widget.existingEvent!['description'] ?? '';
      isPublic = widget.existingEvent!['isPublic'] ?? false;
      
      if (widget.existingEvent!['event_date'] != null) {
        dateTime = DateTime.parse(widget.existingEvent!['event_date']);
        dateController.text = DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime!);
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      setState(() {
        _currentUser = UserModel.fromJson(json.decode(userData));
      });
    }
  }

  Future<List<String>> _uploadSelectedImagesToSupabase() async {
    List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        if (!_validateImageBeforeUpload(file)) continue;

        final fileExt = path.extension(file.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$fileExt';
        
        final fileBytes = await file.readAsBytes();
        
        final uploadResponse = await supabase.storage
            .from('event-photos')
            .uploadBinary('eventphotos/$fileName', fileBytes);

        // If uploadBinary throws, it will be caught by the catch block.
        // Otherwise, uploadResponse is the file path string.
        if (uploadResponse == null || uploadResponse.isEmpty) {
          throw Exception('Upload failed: No file path returned.');
        }

        final response = supabase.storage
            .from('event-photos')
            .getPublicUrl('eventphotos/$fileName');

        uploadedUrls.add(response);
      }
      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Image upload failed');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1440,
      );
      
      if (pickedFiles.isEmpty) return;

      for (final pickedFile in pickedFiles) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: const Color(0xFF328E6E),
              toolbarWidgetColor: Colors.white,
              hideBottomControls: true,
            ),
            IOSUiSettings(title: 'Crop Image'),
          ],
        );
        
        if (cropped != null && mounted) {
          setState(() => _selectedImages.add(File(cropped.path)));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ${e.toString()}')),
      );
    }
  }

  void _confirmDiscard() {
    if (_formKey.currentState?.validate() == true || _selectedImages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Discard changes?"),
          content: const Text("Do you want to continue without saving or save as draft?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Continue Without Saving", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _confirmSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload at least 1 image.")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Submission"),
          content: const Text("Are you sure you want to submit this event?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitEvent();
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
    }
  }

  bool _validateImageBeforeUpload(File file) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    
    if (sizeInMB > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large (max 5MB)')),
      );
      return false;
    }
    
    final ext = path.extension(file.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png'];
    
    if (!validExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image format (only JPG and PNG allowed)')),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _submitEvent() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Creating your event...", style: TextStyle(fontFamily: 'Poppins')),
              ],
            ),
          );
        },
      );
      //Inserting event data to database
      final imageUrls = await _uploadSelectedImagesToSupabase();
      
      final eventData = {
        'title': titleController.text,
        'description': descriptionController.text,
        'event_date': dateTime?.toIso8601String(),
        'volunteers_needed': int.tryParse(volunteersController.text) ?? 0,
        'isPublic': isPublic,
        'approval_status': 'pending',
        'barangay_id': _currentUser?.barangayId,
        'created_by': _currentUser?.id,
        'photo_urls': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (widget.existingEvent != null) {
        // Update existing event
        await supabase
            .from('volunteer_events')
            .update(eventData)
            .eq('event_id', widget.existingEvent!['id']);
      } else {
        // Create new event
        await supabase
            .from('volunteer_events')
            .insert(eventData);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event submitted successfully!')),
        );
        Navigator.pop(context); // Close screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFormBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF328E6E),
          title: Text(
            widget.existingEvent != null ? "Edit Event" : "Create Event",
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _confirmDiscard,
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 60 : 20,
                vertical: 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: _selectedImages.isEmpty
                          ? Container(
                              height: isTablet ? 250 : 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Add Photos', style: TextStyle(fontFamily: 'Poppins')),
                                ],
                              ),
                            )
                          : SizedBox(
                              height: isTablet ? 250 : 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) => Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImages[index],
                                          fit: BoxFit.cover,
                                          width: isTablet ? 250 : 180,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _selectedImages.removeAt(index));
                                        },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black54,
                                          child: Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    _buildFormBox(
                      child: TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Event Title", 
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                        validator: (value) => value!.isEmpty ? "Enter a title" : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFormBox(
                      child: DropdownButtonFormField<bool>(
                        value: isPublic,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Event Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true, 
                            child: Text("Public", style: TextStyle(fontFamily: 'Poppins'))
                          ),
                          DropdownMenuItem(
                            value: false, 
                            child: Text("Private", style: TextStyle(fontFamily: 'Poppins'))
                          ),
                        ],
                        onChanged: (val) => setState(() => isPublic = val),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFormBox(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Suggested Date & Time",
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                        controller: dateController,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          
                          if (picked == null) return;
                          
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (time != null && mounted) {
                            setState(() {
                              dateTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                              dateController.text = DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime!);
                            });
                          }
                        },
                        validator: (_) => dateTime == null ? "Pick a date & time" : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFormBox(
                      child: TextFormField(
                        controller: volunteersController,
                        decoration: const InputDecoration(
                          labelText: "Number of Volunteers", 
                          border: InputBorder.none
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        validator: (value) {
                          if (value!.isEmpty) return "Enter a number";
                          if (int.tryParse(value) == null) return "Enter a valid number";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildFormBox(
                      child: TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: InputBorder.none,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        validator: (value) => value!.isEmpty ? "Enter a description" : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF328E6E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          widget.existingEvent != null ? "Update Event" : "Submit",
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}