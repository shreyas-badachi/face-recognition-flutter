import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import 'Service  Page/face_service.dart';

typedef CaptureCallback = Future<Map<String, dynamic>?> Function(
    String imagePath, Face? face);

class CameraPage extends StatefulWidget {
  final String userId;
  final bool isRegister;
  final CaptureCallback? onCapture;

  const CameraPage({
    super.key,
    required this.userId,
    this.isRegister = false,
    this.onCapture,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  final FaceService _faceService = FaceService();
  bool _isProcessing = false;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  Face? _detectedFace;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _faceService.loadModel();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return;
    }
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;
    await _initController(_cameras![_selectedCameraIdx]);
  }

  Future<void> _initController(CameraDescription camera) async {
    _controller =
        CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    await _initController(_cameras![_selectedCameraIdx]);
  }

  Future<void> _captureFace() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final picture = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final faces = await _faceService.detectFaces(inputImage);

      if (faces.isEmpty) {
        _showSnack("No face detected");
        return;
      }

      final face = faces.first;
      setState(() => _detectedFace = face);

      final result = await widget.onCapture?.call(picture.path, face);
      if (mounted && result != null) {
        Navigator.pop(context, result); // result is bool
      }
    } catch (e) {
      debugPrint("Capture error: $e");
      _showSnack("Error capturing face");
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.isRegister ? "Register Face" : "Verify Face")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegister ? "Register Face" : "Verify Face"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 100), // top padding
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
                const SizedBox(height: 120), // bottom padding
              ],
            ),
          ),

          // Face overlay
          if (_detectedFace != null)
            CustomPaint(
              painter:
                  FacePainter(_detectedFace!, _controller!.value.aspectRatio),
              size: Size.infinite,
            ),
          // Instructions overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.isRegister
                          ? 'Position your face in the frame'
                          : 'Look at the camera',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    GestureDetector(
                      onTap: _captureFace,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_cameras != null && _cameras!.length > 1)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera,
                          color: Colors.white, size: 30),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: const CircleBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final Face face;
  final double aspectRatio;

  FacePainter(this.face, this.aspectRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = face.boundingBox;
    final scaleX = size.width / aspectRatio;
    final scaleY = size.height;

    final scaledRect = Rect.fromLTWH(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.width * scaleX,
      rect.height * scaleY,
    );

    canvas.drawRect(scaledRect, paint);

    // Draw landmarks
    final landmarkPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    face.landmarks.forEach((type, landmark) {
      final point = Offset(
        landmark!.position.x * scaleX,
        landmark.position.y * scaleY,
      );
      canvas.drawCircle(point, 4.0, landmarkPaint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
