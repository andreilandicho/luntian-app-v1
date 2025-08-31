// lagyan ng textfields para sa address para if mag-fail ang geolocation, may manual input. pero kung gumana naman, auto fill na siya.
//ang manual input ay dropdown ng location and hindi free-form ng text para ma-route pa rin ng tama ang report sa barangay.
//currently, apat na barangays muna ang nasa dropdown for barangay na handle ng backend. 628, 630, Calan - for dev purpose, dela paz pib - for dev purposes
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  int currentPage = 0; //0 - for cam then 1 for the address form then 2 for details

  // step 0 for photo
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  final List<File> _capturedImages = []; // Store all captured images
  final Set<int> _selectedImageIndexes = {};


  // step 1 for location and address ng user
  // String? _location;
  final streetController = TextEditingController();
  int? selectedBarangayId;
  String barangayName = "";
  String municipality = "";
  String province = "";
  String region = "";
  List<dynamic> barangays = [];
  bool isFetchingBarangays = false;
  bool isDetectingLocation = false;

  //step 2 for details ng report
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPriority;
  bool? _isHazardous;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchBarangays();
  }


  // ======== PHOTO CAPTURING FOR REPORT ========
  // Future<void> _initializeCamera() async {
  //   await _initializeCamera();
  //   await _determinePosition();
  //   await fetchBarangays();
  // }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.last;
    _cameraController = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() => _isCameraInitialized = true);
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
  Widget _buildPhotoStep() {
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
                    ? () {
                        // Initialize values needed for next step
                        setState(() {
                          // Make sure these have default values if needed
                          barangayName = "";
                          municipality = "";
                          province = "";
                          region = "";
                          currentPage = 1;
                        });
                      }
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

// ======== LOCATION STEP ========
Future<void> _fetchBarangays() async {
    setState(() => isFetchingBarangays = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:3000/barangays'));
      if (res.statusCode == 200) {
        setState(() {
          barangays = jsonDecode(res.body);
        });
      }
    } catch (_) {
    } finally {
      setState(() => isFetchingBarangays = false);
    }
  }
  
 

  //service to detect user's barangay based on location
  Future<void> _detectLocationAndMatch() async {
  setState(() => isDetectingLocation = true);
  
  try {
    // 1. Check if location services are enabled
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable in settings.')),
      );
      return;
    }
    
    // 2. Check/request location permissions
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Please select your location manually.')),
        );
        return;
      }
    }
    
    // 3. Get current position with appropriate accuracy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting your location...')),
    );
    
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    
    // 4. Print coordinates for debugging
    print('Detected location: ${pos.latitude}, ${pos.longitude}');
    
    // 5. Make API request to find matching barangay
    final matchRes = await http.get(Uri.parse(
      'http://10.0.2.2:3000/barangays/match/${pos.latitude}/${pos.longitude}'));
    
    // 6. Process API response
    if (matchRes.statusCode == 200) {
      final data = jsonDecode(matchRes.body);
      print('API Response: $data');
      
      if (data is List && data.isNotEmpty) {
        final matched = data[0];
        
        // Update UI with matched location
        setState(() {
          selectedBarangayId = matched['barangay_id'];
          barangayName = matched['barangay_name'] ?? "";
          municipality = matched['barangay_municipality'] ?? "";
          province = matched['barangay_province'] ?? "";
          region = matched['barangay_region'] ?? "";
        });
        
        // Feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location detected: $barangayName')),
        );
      } else {
        // No match found in the database
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your location does not match any known barangay. Please select manually.')),
        );
      }
    } else {
      _onBarangayDropdownChanged(selectedBarangayId);
      // API call failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to match location. Status: ${matchRes.statusCode}')),
      );
    }
  } catch (e) {
    // Handle all other errors
    _onBarangayDropdownChanged(selectedBarangayId);
    print('Error in _detectLocationAndMatch: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error detecting location: ${e.toString()}')),
    );
  } finally {
    setState(() => isDetectingLocation = false);
  }
}

  void _onBarangayDropdownChanged(int? barangayId) {
  if (barangayId == null) return;
  setState(() {
    selectedBarangayId = barangayId;
    // Find the selected barangay
    final found = barangays.firstWhere(
      (b) => b['barangay_id'] == barangayId,
      orElse: () => <String, dynamic>{},
    );
    // Use the correct property names from the API response
    barangayName = found['barangay_name']?.toString() ?? "";
    municipality = found['barangay_municipality']?.toString() ?? "";
    province = found['barangay_province']?.toString() ?? "";
    region = found['barangay_region']?.toString() ?? "";
  });
}

  Widget _buildAddressStep() {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Address Information",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(
                    labelText: "Street (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                isFetchingBarangays
                    ? const Center(child: CircularProgressIndicator())
                    : (barangays.isEmpty
                        ? const Text("No barangays found. Please try again.")
                        : DropdownButtonFormField<int>(
                            value: selectedBarangayId,
                            decoration: const InputDecoration(
                              labelText: "Barangay",
                              border: OutlineInputBorder(),
                            ),
                            items: barangays
                                .map<DropdownMenuItem<int>>((b) => DropdownMenuItem<int>(
                                      value: b['barangay_id'],
                                      child: Text(b['barangay_name']),
                                    ))
                                .toList(),
                            onChanged: _onBarangayDropdownChanged,
                            validator: (val) =>
                                val == null ? "Please select barangay" : null,
                          )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Municipality/City",
                          border: OutlineInputBorder(),
                          hintText: "Auto-filled",
                        ),
                        controller: TextEditingController(text: municipality),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Province",
                          border: OutlineInputBorder(),
                          hintText: "Auto-filled",
                        ),
                        controller: TextEditingController(text: province),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Region",
                    border: OutlineInputBorder(),
                    hintText: "Auto-filled",
                  ),
                  controller: TextEditingController(text: region),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: isDetectingLocation ? null : _detectLocationAndMatch,
                  icon: const Icon(Icons.my_location),
                  label: Text(isDetectingLocation
                      ? "Detecting..."
                      : "Auto-fill using location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF328E6E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const Spacer(), // This will push the Next button to the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: (selectedBarangayId != null)
                          ? () => setState(() => currentPage = 2)
                          : null,
                      child: const Text("Next"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ======== Details Step ========


  Widget _buildDetailsStep() {
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

                

                // Category
                _buildFormBox(
                  child: DropdownButtonFormField<String>(
                    value: (_selectedCategory != null && _selectedCategory != "") ? _selectedCategory : null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Category',
                    ),
                    items: ['General', //1 - value in database
                            'Baradong Kanal', //2
                            'Masangsang na Estero', //3
                            'Tagas ng Langis/Oil Spills', //4
                            'Tambak ng Basura'] //5
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
                    value: (_selectedPriority != null && _selectedPriority != "") ? _selectedPriority : null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Priority',
                    ),
                    items: ['Low', //1 - value in database
                            'Medium', //2 - value in database
                            'High'] //3 - value in database
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
                    value: (_isHazardous != null) ? _isHazardous : null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Nakakalason/Hazardous?',
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text("Yes", style: TextStyle(fontFamily: 'Poppins'))), //1 - value in database
                      DropdownMenuItem(value: false, child: Text("No", style: TextStyle(fontFamily: 'Poppins'))), //0 - value in database
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
                    if (!_validateDetailsForm()) {
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

  bool _validateDetailsForm() {
    if (_selectedImageIndexes.isEmpty) return false;
    if (_selectedCategory == null) return false;
    if (_selectedPriority == null) return false;
    if (_isHazardous == null) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    // Address
    if (selectedBarangayId == null) return false;
    return true;
  }

  //For report submission
  Future<void> _submitReport() async {
    // TODO: Implement backend POST for report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted Successfully!')),
    );
    Navigator.pop(context);
  }


  @override
  void dispose() {
    _cameraController.dispose();
    _descriptionController.dispose();
    streetController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  Widget stepWidget;
  if (currentPage == 0) {
    stepWidget = _buildPhotoStep();
  } else if (currentPage == 1) {
    stepWidget = _buildAddressStep();
  } else {
    stepWidget = _buildDetailsStep();
  }
  return WillPopScope(
    onWillPop: () async {
      if (currentPage == 1) {
        setState(() => currentPage = 0);
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
    if (currentPage == 0) {
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
      setState(() => currentPage = 0); // Go back to camera page
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
      body: stepWidget
    ),
  );
}
}