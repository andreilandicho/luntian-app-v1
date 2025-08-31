import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'upload.dart'; // Import the next page
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
  XFile? _capturedImage;

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

  /// Capture photo
  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  /// Retake photo
  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
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
          /// CAMERA PREVIEW or CAPTURED PHOTO
          Positioned.fill(
            child: _capturedImage == null
                ? FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          _controller != null) {
                        return CameraPreview(_controller!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                : Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),

          /// OVERLAY BUTTONS
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_capturedImage == null) ...[
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
                ] else ...[
                  /// Retake Button
                  ElevatedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    label: const Text(
                      "Retake",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // <-- bold text
                        fontSize: 16, // optional
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 20),


                  /// Use Button → Go to ProofReviewPage
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProofReviewPage(imagePath: _capturedImage!.path),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text(
                      "Use Photo",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // <-- makes text bold
                        fontSize: 16, // optional: adjust size
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                    ),
                  ),

                ]
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
