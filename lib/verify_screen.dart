import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;

import 'Service  Page/face_service.dart';
import 'app_theme.dart';
import 'camera_page.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final FaceService _faceService = FaceService();
  bool _isLoading = false;
  String? _recognizedName;
  bool? _isMatch;

  @override
  void initState() {
    super.initState();
    _faceService.loadModel();
  }

  Future<void> _verifyFace() async {
    setState(() => _isLoading = true);
    _recognizedName = null;
    _isMatch = null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(
          userId: '',
          isRegister: false,
          onCapture: (imagePath, face) async {
            try {
              final imageBytes = await File(imagePath).readAsBytes();
              final image = img.decodeImage(imageBytes);
              if (image != null && face != null) {
                final tensor = _faceService.preprocessFace(image, face);
                final embedding = _faceService.getEmbedding(tensor);

                // Find matching user
                final allKeys = Hive.box('faceBox').keys.where((k) => k.toString().startsWith('embeddings_')).toList();
                String? matchedUser;
                double maxSimilarity = -1.0;

                for (var key in allKeys) {
                  final userId = key.toString().replaceFirst('embeddings_', '');
                  final embeddings = _faceService.getUserEmbeddings(userId);
                  if (embeddings != null && _faceService.isMatchMultiple(embeddings, embedding)) {
                    matchedUser = userId;
                    break;
                  }
                }

                return {
                  'matched': matchedUser != null,
                  'name': matchedUser ?? 'Unknown',
                };
              }
            } catch (e) {
              debugPrint('Verification error: $e');
            }
            return {
              'matched': false,
              'name': 'Unknown',
            };
          },
        ),
      ),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      setState(() {
        _recognizedName = result['name'];
        _isMatch = result['matched'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMatch!
              ? 'Welcome, $_recognizedName! ✅'
              : 'No match found for $_recognizedName ❌'),
          backgroundColor: _isMatch! ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Face'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Look at the camera to verify your identity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face,
                        size: 64,
                        color: AppTheme.primaryBlue.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Face verification in progress',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (_recognizedName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _isMatch! ? Icons.check_circle : Icons.cancel,
                        size: 48,
                        color: _isMatch! ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _recognizedName!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMatch! ? 'Access Granted' : 'Access Denied',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isMatch! ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyFace,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.camera),
              label: const Text('Start Verification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}