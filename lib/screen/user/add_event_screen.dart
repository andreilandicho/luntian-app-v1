import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';

class AddEventScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEvent;

  const AddEventScreen({super.key, this.existingEvent});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {

  @override
void initState() {
  super.initState();
  if (widget.existingEvent != null) {
    title = widget.existingEvent!['postContent'];
    numberOfVolunteers = widget.existingEvent!['volunteers'];
    description = widget.existingEvent!['postContent'];
    details = widget.existingEvent!['adminComment'];
    // Optional: Set sample datetime or leave as is
  }
}

  final ImagePicker picker = ImagePicker();
  final List<File> _selectedImages = [];
  final _formKey = GlobalKey<FormState>();

  String? title;
  DateTime? dateTime;
  int? numberOfVolunteers;
  String? description;
  String? details;

  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (final pickedFile in pickedFiles) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
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
        if (cropped != null) {
          setState(() => _selectedImages.add(File(cropped.path)));
        }
      }
    }
  }

  void _confirmDiscard() {
    if (_formKey.currentState!.validate() || _selectedImages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Discard changes?"),
          content: const Text("Do you want to continue without saving or save as draft?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Save as draft simulation
              },
              child: const Text("Save as Draft"),
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

      _formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Submission"),
          content: const Text("Are you sure you want to submit this event?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Event Submitted")),
                );
                Navigator.pop(context);
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

  return WillPopScope(
    onWillPop: () async {
      _confirmDiscard();
      return false;
    },
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF328E6E),
        title: const Text("Create Event", style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
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
                            child: const Center(
                              child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
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
                      decoration: const InputDecoration(labelText: "Event Title", border: InputBorder.none),
                      style: const TextStyle(fontFamily: 'Poppins'),
                      validator: (value) => value!.isEmpty ? "Enter a title" : null,
                      onSaved: (value) => title = value,
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
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              dateTime = DateTime(
                                  picked.year, picked.month, picked.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      controller: TextEditingController(
                        text: dateTime != null
                            ? DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime!)
                            : '',
                      ),
                      validator: (_) => dateTime == null ? "Pick a date & time" : null,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildFormBox(
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: "Number of Volunteers", border: InputBorder.none),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      validator: (value) => value!.isEmpty ? "Enter a number" : null,
                      onSaved: (value) => numberOfVolunteers = int.tryParse(value ?? "0"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildFormBox(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      validator: (value) => value!.isEmpty ? "Enter a description" : null,
                      onSaved: (value) => description = value,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildFormBox(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Additional Details (Location, Who's Needed, etc.)",
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      onSaved: (value) => details = value,
                    ),
                  ),
                  const SizedBox(height: 30),

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
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
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