import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
class MediaUploadService {
  MediaUploadService(this._storage);

  final FirebaseStorage _storage;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get uploadProgress => _progressController.stream;

  static const _allowedImageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const _maxRetries = 3;

  static String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot).toLowerCase() : '';
  }

  Future<String> uploadImage(File file, String reportId) async {
    final ext = _ext(file.path);
    if (!_allowedImageExtensions.contains(ext)) {
      throw const MediaUploadException('Unsupported image format');
    }

    final compressed = await _compressImage(file);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? ext : '.jpg'}';
    final ref = _storage.ref('hazard_reports/$reportId/images/$fileName');
    return _uploadWithRetry(compressed ?? file, ref);
  }

  Future<String> uploadVoiceNote(File file, String reportId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref('hazard_reports/$reportId/voice/$fileName');
    return _uploadWithRetry(file, ref);
  }

  Future<File?> _compressImage(File file) async {
    final targetPath = '${file.path}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: 1280,
      minHeight: 1,
      quality: 75,
    );
    if (result == null) return null;
    return File(result.path);
  }

  Future<String> _uploadWithRetry(File file, Reference ref) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final task = ref.putFile(file);
        task.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          if (total > 0) {
            _progressController.add(snap.bytesTransferred / total);
          }
        });
        await task;
        return await ref.getDownloadURL();
      } catch (e) {
        if (attempt == _maxRetries) {
          throw MediaUploadException('Upload failed after $_maxRetries attempts', cause: e);
        }
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw const MediaUploadException('Upload failed');
  }

  void dispose() => _progressController.close();
}

class MediaUploadException implements Exception {
  const MediaUploadException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'MediaUploadException: $message${cause != null ? ' ($cause)' : ''}';
}
