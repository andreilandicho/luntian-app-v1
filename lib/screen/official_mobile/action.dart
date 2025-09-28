import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'upload.dart'; // Your next page
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';

class ProofAction extends StatefulWidget {
  final int reportId;
  const ProofAction({super.key, required this.reportId});

  @override
  State<ProofAction> createState() => _ProofActionState();
}

class _ProofActionState extends State<ProofAction> {
  int selectedIndex = 0;
  bool isNavVisible = true;

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<XFile> _capturedImages = [];
  XFile? _selectedImage;

  final Set<int> _selectedImageIndexes = {};

  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;

  bool _isCapturing = false; 

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      _selectedCameraIdx = 0; // Default to rear
      final isRear = _cameras![_selectedCameraIdx].lensDirection == CameraLensDirection.back;
      _controller = CameraController(
        _cameras![_selectedCameraIdx],
        isRear ? ResolutionPreset.low : ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    _controller?.dispose();
    final isRear = _cameras![_selectedCameraIdx].lensDirection == CameraLensDirection.back;
    _controller = CameraController(
      _cameras![_selectedCameraIdx],
      isRear ? ResolutionPreset.low : ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return; // Prevent double capture
    _isCapturing = true;
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
        _selectedImage = image;
      });
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    } finally {
      _isCapturing = false;
    }
  }

  void _retakeAllPhotos() {
    setState(() {
      _capturedImages.clear();
      _selectedImage = null;
      _selectedImageIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: LuntianHeader(
        isSmallScreen: isSmallScreen,
      ),
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _controller != null) {
                  return CameraPreview(_controller!);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),

          /// THUMBNAIL PREVIEW
          if (_capturedImages.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    final image = _capturedImages[index];
                    final isSelected = _selectedImageIndexes.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isSelected ? _selectedImageIndexes.remove(index) : _selectedImageIndexes.add(index);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Image.file(
                          File(image.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ... inside your build method, replacing the // BUTTONS Positioned widget:

/// BUTTONS
Positioned(
  bottom: 30,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Retake All Button (leftmost)
        if (_capturedImages.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _retakeAllPhotos,
            icon: const Icon(Icons.refresh, color: Colors.red),
            label: const Text(
              "Retake All",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
            ),
          )
        else
          const SizedBox(width: 110), // Placeholder to keep spacing

        // Camera Button (center left)
        ElevatedButton(
          onPressed: _isCapturing ? null : _capturePhoto,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            backgroundColor: Colors.white,
          ),
          child: const Icon(Icons.camera_alt,
              color: Colors.black, size: 30),
        ),

        // Switch Camera Button (center right)
        ElevatedButton(
          onPressed: _switchCamera,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
          ),
          child: const Icon(Icons.flip_camera_ios, color: Colors.black, size: 28),
        ),

        // Use Selected Button (rightmost)
        if (_selectedImageIndexes.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {
              final selectedPaths = _selectedImageIndexes.map((i) => _capturedImages[i].path).toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProofReviewPage(
                    imagePaths: selectedPaths,
                    reportId: widget.reportId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text(
              "Use Selected",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
            ),
          )
        else
          const SizedBox(width: 120), // Placeholder for spacing
      ],
    ),
  ),
),
        ],
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