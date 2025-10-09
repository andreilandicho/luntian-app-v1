import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/user_model.dart'; //for current user
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  int currentPage = 0; //0 - for cam then 1 for the address form then 2 for details

  // step 0 for photo

  List<CameraDescription>? _cameras;
  late CameraController _cameraController;
  int _selectedCameraIdx = 0; //0 means rear cam conventionally
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  final List<File> _capturedImages = []; // Store all captured images
  final Set<int> _selectedImageIndexes = {};
  bool _isAnonymous = false;



  // step 1 for location and address ng user
  Position? _currentLocation;
  final descriptiveLocation = TextEditingController();
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

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchBarangays();
    _loadCurrentUser();
  }

  //Function to load current user data
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      setState(() {
        _currentUser = UserModel.fromJson(json.decode(userData));
      });
    }
  }

  // ======== PHOTO CAPTURING FOR REPORT ========
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    // Default to rear camera: typically CameraLensDirection.back
    _selectedCameraIdx = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (_selectedCameraIdx == -1) _selectedCameraIdx = 0; // fallback to first camera
    _cameraController = CameraController(_cameras![_selectedCameraIdx], ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return; // nothing to switch
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    await _cameraController.dispose();
    _cameraController = CameraController(_cameras![_selectedCameraIdx], ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() {});
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
  
  // Method to upload selected images to Supabase
  Future<List<String>> _uploadSelectedImagesToSupabase() async {
    List<String> uploadedUrls = [];
    
    // Get selected images
    final selectedImages = _selectedImageIndexes.map((i) => _capturedImages[i]).toList();
    

    try {
      // Upload each selected image
      for (int i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];
        final fileExt = path.extension(file.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$fileExt';
        
        // Read file as bytes
        final bytes = await file.readAsBytes();
        
        // Upload to Supabase
        await supabase.storage
            .from('report-images') // Your bucket name
            .uploadBinary(
              'reports/$fileName', // Path in the bucket
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );
        
        // Get public URL for the uploaded file
        final imageUrl = supabase.storage
            .from('report-images')
            .getPublicUrl('reports/$fileName');
        
        uploadedUrls.add(imageUrl);
      }
      
      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: ${e.toString()}')),
      );
      return [];
    } 
    // finally {
    //   // Close progress dialog
    //   Navigator.of(context).pop();
    // }
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
                      onPressed: _switchCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                        elevation: 6,
                      ),
                      child: const Icon(Icons.flip_camera_android, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 20),
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
      //request url
      final res = await http.get(Uri.parse('https://luntian-app-v1-production.up.railway.app/barangays'));
      if (res.statusCode == 200) {
        setState(() {
          barangays = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print('Error fetching barangays: $e');
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
      
      // Store the position for later use
      _currentLocation = pos;
      
      // 4. Print coordinates for debugging
      print('Detected location: ${pos.latitude}, ${pos.longitude}');
      
      // 5. Make API request to find matching barangay
      //request url
      final matchRes = await http.get(Uri.parse(
        'https://luntian-app-v1-production.up.railway.app/barangays/match/${pos.latitude}/${pos.longitude}'));

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
        if (selectedBarangayId != null) {
          _onBarangayDropdownChanged(selectedBarangayId);
        }
        // API call failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to match location. Status: ${matchRes.statusCode}')),
        );
      }
    } catch (e) {
      // Handle all other errors
      if (selectedBarangayId != null) {
        _onBarangayDropdownChanged(selectedBarangayId);
      }
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
                    controller: descriptiveLocation,
                    decoration: const InputDecoration(
                      labelText: "Descriptive Location (e.g., street, landmark)",
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
                        ? "Geotagging..."
                        : "Geotag"),
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
                      // fix this part based on SLA
                      items: ['General Littering', //1 - value in database
                              'Baradong Kanal', //2
                              'Masangsang na Estero', //3
                              'Tambak ng Basura', //5
                              'Patay na Hayop (Dead Animals)', //6
                              'Nabasag na Bote / Debris', //7
                              'Illegal Dumping', //8
                              'Oil/Chemical Spills' //9
                              ]
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

                  SwitchListTile(
                    title: const Text(
                      "Submit as Anonymous",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    activeColor: const Color(0xFF328E6E),
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),


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
                        await _submitReport(); // Call the _submitReport method
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

  bool _validateImageBeforeUpload(File file) {
    // Check file size (limit to 5MB)
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    
    if (sizeInMB > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large (max 5MB)')),
      );
      return false;
    }
    
    // Validate file extension
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

  //For report submission
  Future<void> _submitReport() async {
    try {
      // 1. Show loading indicator
      BuildContext? dialogContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          dialogContext = context;
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
              Text("Submitting your report...", style: TextStyle(fontFamily: 'Poppins')),
            ],
          ),
        );
      },
    );
      
      // 2. Validate images before uploading
      final selectedImages = _selectedImageIndexes.map((i) => _capturedImages[i]).toList();
      
      for (var img in selectedImages) {
        if (!_validateImageBeforeUpload(img)) {
          // Close loading dialog if validation fails
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
      
      // 3. Upload images
      final imageUrls = await _uploadSelectedImagesToSupabase();
      if (imageUrls.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        throw Exception("Failed to upload images");
      }

      // Function to calculate deadline based on rules
      DateTime _calculateDeadline({
        required String category,
        required bool hazardous,
        required String priority,
      }) {
        final now = DateTime.now();
        final cat = category.toLowerCase();
        final pri = priority.toLowerCase();

        if (cat.contains("baradong kanal")) {
          if (!hazardous && pri == "low") return now.add(const Duration(hours: 72));
          if (!hazardous && pri == "medium") return now.add(const Duration(hours: 48));
          if (hazardous && pri == "high") return now.add(const Duration(hours: 24));
        }

        if (cat.contains("tambak ng basura")) {
          if (!hazardous && pri == "low") return now.add(const Duration(hours: 168));
          if (hazardous && pri == "medium") return now.add(const Duration(hours: 48));
          if (hazardous && pri == "high") return now.add(const Duration(hours: 24));
        }

        if (cat.contains("masangsang na estero")) {
          if (!hazardous && pri == "low") return now.add(const Duration(hours: 72));
          if (!hazardous && pri == "medium") return now.add(const Duration(hours: 48));
          if (hazardous && pri == "high") return now.add(const Duration(hours: 24));
        }

        if (cat.contains("oil") || cat.contains("chemical")) {
          if (hazardous && pri == "high") return now.add(const Duration(hours: 4));
        }

        if (cat.contains("general littering")) {
          if (!hazardous && pri == "low") return now.add(const Duration(hours: 168));
        }

        if (cat.contains("nabasag") || cat.contains("debris")) {
          if (hazardous && pri == "medium") return now.add(const Duration(hours: 48));
        }

        if (cat.contains("patay") || cat.contains("hayop")) {
          if (hazardous && pri == "medium") return now.add(const Duration(hours: 48));
        }

        if (cat.contains("illegal dumping")) {
          if (hazardous && pri == "high") return now.add(const Duration(hours: 48));
        }

        // Default fallback
        return now.add(const Duration(days: 7));
      }

      // Calculate deadline based on category, hazardous, and priority
      final deadline = _calculateDeadline(
        category: _selectedCategory!,
        hazardous: _isHazardous ?? false,
        priority: _selectedPriority!,
      );

      
      // 4. Prepare report data
      final reportData = {
        'user_id': _currentUser?.id, // Assuming user is logged in
        'barangay_id': selectedBarangayId,
        'descriptive_location': descriptiveLocation.text.trim(),
        'description': _descriptionController.text.trim(),
        'photo_urls': imageUrls,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'hazardous': _isHazardous,
        'status': 'pending', // Default status
        'created_at': DateTime.now().toIso8601String(),
        'report_deadline': deadline.toIso8601String(),
        'anonymous': _isAnonymous, // ✅ include toggle result // ✅ new field
      };
      
      // Add location if available
      if (_currentLocation != null) {
        reportData['lat'] = _currentLocation!.latitude;
        reportData['lon'] = _currentLocation!.longitude; // Use lon for longitude in Supabase
      }
      
      // 5. Submit report to Supabase database
      final response = await supabase
          .from('reports')
          .insert(reportData)
          .select()
          .single();

      final reportId = response['report_id']; // ✅ matches Supabase table

      //emailer insert
      //request url
      final backendRes = await http.post(
        Uri.parse("https://luntian-app-v1-production.up.railway.app/notif/notifBarangay"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"report_id": reportId}),
      );

      if (backendRes.statusCode == 200) {
        print("✅ Barangay notification triggered successfully");
      } else {
        print("❌ Backend error: ${backendRes.body}");
      }

      // 6. clean up local images
      await _cleanupLocalImages();
      
      // 7. Close loading dialog
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext!).pop();
      }
      // 8. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
      }
      // 9. Navigate back (with a slight delay to avoid navigation conflicts)
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) { // Check if widget is still mounted
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: ${e.toString()}')),
      );
    }
  }

  Future<void> _cleanupLocalImages() async {
    // Delete all temporary captured images
    for (var image in _capturedImages) {
      try {
        await image.delete();
      } catch (e) {
        print('Error deleting local image: $e');
      }
    }
  }

  //close and dispose controllers na ginamit
  @override
  void dispose() {
    _cameraController.dispose();
    _descriptionController.dispose();
    descriptiveLocation.dispose();
    super.dispose();
  }
  
  //for the back button functionality 
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
            currentPage == 1 ? "Address Information" : (currentPage == 2 ? "Report Details" : "Capture Evidence"),
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