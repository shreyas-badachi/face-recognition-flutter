import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'Service  Page/face_service.dart';
import 'app_theme.dart';
import 'camera_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FaceService _faceService = FaceService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _faceService.loadModel();
  }

  Future<void> _registerFace() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(
          userId: _nameController.text,
          isRegister: true,
          onCapture: (imagePath, face) async {
            try {
              final imageBytes = await File(imagePath).readAsBytes();
              final image = img.decodeImage(imageBytes);
              if (image != null && face != null) {
                debugPrint("📸 Face detected, generating embeddings...");
                final embeddings = await _faceService.generateAugmentedEmbeddings(
                  image,
                  face,
                  [],
                );

                debugPrint("✅ Embeddings generated: ${embeddings.take(5).toList()}"); // first 5 values

                await _faceService.saveUserEmbeddings(
                  _nameController.text,
                  embeddings,
                );

                return {
                  'success': true,
                  'name': _nameController.text,
                };
              }
            } catch (e, s) {
              debugPrint('❌ Registration error: $e');
              debugPrint('Stack: $s');
            }

            return {
              'success': false,
              'name': _nameController.text,
            };
          },

        ),
      ),
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face registered successfully for ${result['name']}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face registration failed. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Face'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.lightGray,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Position your face clearly in the camera frame',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 200,
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 64,
                        color: AppTheme.primaryBlue.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to capture face',
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
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _registerFace,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.camera),
              label: const Text('Capture & Register'),
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
