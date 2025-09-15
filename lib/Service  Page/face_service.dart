import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  Interpreter? _interpreter;
  final Box _box = Hive.box('faceBox');
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  /// Load the MobileFaceNet model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/FaceMobileNet_Float32.tflite');
      debugPrint("✅ MobileFaceNet model loaded");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
    }
  }

  /// Get 192-dimensional embedding from [1,112,112,3] tensor
  List<double> getEmbedding(List<List<List<List<double>>>> input) {
    if (_interpreter == null) {
      debugPrint("❌ Model not loaded");
      return List.filled(192, 0.0);
    }

    final inputTensor = Float32List(1 * 112 * 112 * 3);
    int idx = 0;
    for (int i = 0; i < 112; i++) {
      for (int j = 0; j < 112; j++) {
        for (int k = 0; k < 3; k++) {
          inputTensor[idx++] = input[0][i][j][k];
        }
      }
    }

    final output = List.generate(1, (_) => List.filled(192, 0.0));
    debugPrint("📌 Running model on input tensor...");
    _interpreter!.run(inputTensor.reshape([1, 112, 112, 3]), output);
    debugPrint("📌 Raw output embedding: ${output[0].take(5).toList()}...");

    return output[0];
  }

  /// Preprocess face to [1,112,112,3] tensor
  List<List<List<List<double>>>> preprocessFace(img.Image image, Face face) {
    final rect = face.boundingBox;
    final size = max(rect.width, rect.height).toInt();
    final x = (rect.center.dx - size / 2).clamp(0, image.width - size).toInt();
    final y = (rect.center.dy - size / 2).clamp(0, image.height - size).toInt();
    var cropped = img.copyCrop(image, x: x, y: y, width: size, height: size);

    // Align face horizontally using eyes if available
    if (face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;
      final angle = atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x) * 180 / pi;
      cropped = img.copyRotate(cropped, angle: -angle);
    }

    final resized = img.copyResize(cropped, width: 112, height: 112);
    final bytesList = resized.getBytes(order: img.ChannelOrder.rgba);

    int index = 0;
    final tensor = List.generate(
      1,
          (_) => List.generate(
        112,
            (yy) => List.generate(
          112,
              (xx) {
            final r = bytesList[index++] / 127.5 - 1.0;
            final g = bytesList[index++] / 127.5 - 1.0;
            final b = bytesList[index++] / 127.5 - 1.0;
            index++; // skip alpha
            return [r, g, b];
          },
        ),
      ),
    );

    return tensor;
  }

  /// Generate multiple augmented embeddings for registration
  Future<List<List<double>>> generateAugmentedEmbeddings(
      img.Image image,
      Face face,
      List<int> augmentations
      ) async {
    List<List<double>> embeddings = [];
    final angles = [-10, 0, 10];
    final shifts = [-5, 0, 5];

    for (var angle in angles) {
      for (var dx in shifts) {
        for (var dy in shifts) {
          var augImage = img.copyRotate(image, angle: angle);

          // ✅ FIX: use .toDouble() instead of `as double`
          final rect = face.boundingBox.translate(
            dx.toDouble(),
            dy.toDouble(),
          );

          final size = max(rect.width, rect.height).toInt();
          final x = (rect.center.dx - size / 2).clamp(0, augImage.width - size).toInt();
          final y = (rect.center.dy - size / 2).clamp(0, augImage.height - size).toInt();

          var cropped = img.copyCrop(augImage, x: x, y: y, width: size, height: size);

          final resized = img.copyResize(cropped, width: 112, height: 112);
          final bytesList = resized.getBytes(order: img.ChannelOrder.rgba);

          int index = 0;
          final tensor = List.generate(
            1,
                (_) => List.generate(
              112,
                  (yy) => List.generate(
                112,
                    (xx) {
                  final r = bytesList[index++] / 127.5 - 1.0;
                  final g = bytesList[index++] / 127.5 - 1.0;
                  final b = bytesList[index++] / 127.5 - 1.0;
                  index++;
                  return [r, g, b];
                },
              ),
            ),
          );

          final embedding = getEmbedding(tensor);
          embeddings.add(embedding);
        }
      }
    }


    return embeddings;
  }

  /// Save multiple embeddings for a user
  Future<void> saveUserEmbeddings(String userId, List<List<double>> embeddings) async {
    await _box.put('embeddings_$userId', embeddings);
    debugPrint("💾 Saved ${embeddings.length} embeddings for userId: $userId");
  }

  /// Retrieve all embeddings for a user
  List<List<double>>? getUserEmbeddings(String userId) {
    final embList = _box.get('embeddings_$userId');
    if (embList == null) return null;
    return List<List<double>>.from(
        (embList as List).map((e) => List<double>.from(e as List))
    );
  }

  /// Compare with multiple embeddings using cosine similarity
  bool isMatchMultiple(List<List<double>> savedEmbeddings, List<double> newEmb, {double threshold = 0.6}) {
    double maxSimilarity = -1.0;
    for (var emb in savedEmbeddings) {
      double dotProduct = 0.0;
      double normA = 0.0;
      double normB = 0.0;

      for (int i = 0; i < emb.length; i++) {
        dotProduct += emb[i] * newEmb[i];
        normA += emb[i] * emb[i];
        normB += newEmb[i] * newEmb[i];
      }

      final similarity = dotProduct / (sqrt(normA) * sqrt(normB));
      if (similarity > maxSimilarity) maxSimilarity = similarity;
    }
    debugPrint("📊 Max cosine similarity: $maxSimilarity, threshold: $threshold");
    return maxSimilarity > threshold;
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _interpreter?.close();
    _faceDetector.close();
  }
}