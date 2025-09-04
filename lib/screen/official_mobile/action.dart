import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'upload.dart'; // Your next page
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';

class ProofAction extends StatefulWidget {
  const ProofAction({super.key});

  @override
  State<ProofAction> createState() => _ProofActionState();
}

class _ProofActionState extends State<ProofAction> {
  int selectedIndex = 0;
  bool isNavVisible = true;
  String _currentAddress = 'Your Address';

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<XFile> _capturedImages = [];
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
        _selectedImage = image;
      });
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  void _retakeAllPhotos() {
    setState(() {
      _capturedImages.clear();
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: LuntianHeader(
        currentAddress: _currentAddress,
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
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedImage == image
                                ? Colors.green
                                : Colors.white,
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

          /// BUTTONS
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Capture Button
                ElevatedButton(
                  onPressed: _capturePhoto,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(18),
                    backgroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.black, size: 30),
                ),
                const SizedBox(width: 20),

                /// Retake All Button
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
                  ),
                const SizedBox(width: 20),

                /// Use Selected Button
                if (_selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProofReviewPage(imagePath: _selectedImage!.path),
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
                  ),
              ],
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