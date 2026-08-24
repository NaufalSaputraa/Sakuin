import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/result.dart';

/// Wraps [ImagePicker] + [ImageCropper] into a single camera/crop pipeline.
///
/// All methods return a structured [Result] (never a raw [Map]):
/// - [Success] carries the cropped image file path.
/// - [Failure] carries an [AppError] (permission denied, cancelled, or parse error).
class CameraService {
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  /// Capture from camera, then open the cropper. Returns cropped file path.
  Future<Result<String, AppError>> pickAndCropFromCamera() {
    return _pickAndCrop(ImageSource.camera);
  }

  /// Pick from gallery, then open the cropper. Returns cropped file path.
  Future<Result<String, AppError>> pickAndCropFromGallery() {
    return _pickAndCrop(ImageSource.gallery);
  }

  /// Crop an already-existing image at [path]. Returns cropped file path.
  Future<Result<String, AppError>> cropImage(String path) async {
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: const Color(0xFF6B5CE7),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
          ),
        ],
      );

      if (cropped == null) {
        // User cancelled the crop UI.
        return Failure(AppError.validation('Cropping cancelled'));
      }
      return Success(cropped.path);
    } on Exception catch (e) {
      return Failure(AppError.parse('Failed to crop image: $e'));
    }
  }

  Future<Result<String, AppError>> _pickAndCrop(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked == null) {
        // Null can mean user cancelled OR permission denied (platform dependent).
        return const Failure(
          PermissionError('Camera permission denied or capture cancelled'),
        );
      }

      return cropImage(picked.path);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('permission')) {
        return Failure(PermissionError('Camera permission denied: $e'));
      }
      return Failure(AppError.parse('Failed to capture image: $e'));
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
