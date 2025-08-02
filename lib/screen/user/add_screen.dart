import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  int currentPage = 1;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;

  final List<File> _capturedImages = [];
  final Set<int> _selectedImageIndexes = {};
  String? _location;
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPriority;
  bool? _isHazardous;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    await _initializeCamera();
    await _determinePosition();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.last;

    _cameraController = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
    await _initializeControllerFuture;

    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _location = "${place.street}, ${place.locality}";
      });
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final name = path.basename(image.path);
      final savedImage = await File(image.path).copy('${directory.path}/$name');
      setState(() {
        _capturedImages.add(savedImage);
      });
    } catch (e) {
      print(e);
    }
  }

 Widget _buildCameraPage() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final double screenWidth = constraints.maxWidth;
      final double cameraPreviewHeight = screenWidth * 3 / 4;

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Camera Preview
              Container(
                width: screenWidth,
                height: cameraPreviewHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),

              const SizedBox(height: 12),

              // Captured Image Grid
              if (_capturedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_capturedImages.length, (index) {
                      final isSelected = _selectedImageIndexes.contains(index);
                      final imageSize = (screenWidth - 64) / 4;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isSelected
                                ? _selectedImageIndexes.remove(index)
                                : _selectedImageIndexes.add(index);
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_capturedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _takePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF328E6E),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(18),
                      elevation: 6,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _selectedImageIndexes.isNotEmpty
                        ? () => setState(() => currentPage = 2)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF328E6E),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

    bool _validateForm() {
    if (_selectedImageIndexes.isEmpty) return false;
    if (_location == null || _location!.isEmpty) return false;
    if (_selectedCategory == null) return false;
    if (_selectedPriority == null) return false;
    if (_isHazardous == null) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    return true;
  }

  Widget _buildFormPage() {
  final selectedImages = _selectedImageIndexes.map((i) => _capturedImages[i]).toList();

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Report Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),

                // Selected Images
                if (selectedImages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedImages
                        .map((img) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 16),

                // Location
                GestureDetector(
                  onTap: _determinePosition,
                  child: Text(
                    'Location: ${_location ?? "Fetching..."}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF328E6E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                _buildFormBox(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Category',
                    ),
                    items: ['General', 'Sanitation', 'Structural']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontFamily: 'Poppins')),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                _buildFormBox(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Priority',
                    ),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p, style: const TextStyle(fontFamily: 'Poppins')),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPriority = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Hazardous
                _buildFormBox(
                  child: DropdownButtonFormField<bool>(
                    value: _isHazardous,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Hazardous?',
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text("Yes", style: TextStyle(fontFamily: 'Poppins'))),
                      DropdownMenuItem(value: false, child: Text("No", style: TextStyle(fontFamily: 'Poppins'))),
                    ],
                    onChanged: (val) => setState(() => _isHazardous = val),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildFormBox(
                  child: TextField(
                    controller: _descriptionController,
                    maxLength: 200,
                    maxLines: 6,
                    textAlign: TextAlign.start,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      counterStyle: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: () async {
                    if (!_validateForm()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all fields.')),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Submit Post", style: TextStyle(fontFamily: 'Poppins')),
                        content: const Text("Are you sure you want to submit?", style: TextStyle(fontFamily: 'Poppins')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Submit", style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Submitted Successfully!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF328E6E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
    },
  );
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
          )
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      if (currentPage == 2) {
        setState(() => currentPage = 1);
        return false;
      }
      return true;
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF328E6E),
        leading: IconButton(
  icon: Icon(currentPage == 1 ? Icons.close : Icons.arrow_back),
  onPressed: () async {
    if (currentPage == 1) {
      // Check if there's draft-worthy content
      bool hasDraftData = _selectedImageIndexes.isNotEmpty ||
                          _descriptionController.text.trim().isNotEmpty ||
                          _selectedCategory != null ||
                          _selectedPriority != null ||
                          _isHazardous != null;

      if (hasDraftData) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Save as Draft", style: TextStyle(fontFamily: 'Poppins')),
            content: const Text("You have unsaved changes. Save as draft?", style: TextStyle(fontFamily: 'Poppins')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Discard", style: TextStyle(fontFamily: 'Poppins')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Save Draft", style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          // 👉 Save to local storage or memory (not implemented here)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Draft saved.")),
          );
        }
      }

      Navigator.pop(context); // Close the page regardless
    } else {
      setState(() => currentPage = 1); // Go back to camera page
    }
  },
),
        title: Text(
          currentPage == 1 ? "Capture Evidence" : "Report Details",
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white, // ✅ White header text
          ),
        ),
      ),
      body: currentPage == 1 ? _buildCameraPage() : _buildFormPage(), // ✅ BODY ADDED HERE
    ),
  );
}
}
