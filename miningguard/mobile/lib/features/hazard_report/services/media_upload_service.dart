import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class InvalidFileTypeException implements Exception {
  const InvalidFileTypeException(this.message);
  final String message;

  @override
  String toString() => 'InvalidFileTypeException: $message';
}

class MediaUploadException implements Exception {
  const MediaUploadException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'MediaUploadException: $message${cause != null ? ' ($cause)' : ''}';
}

class MediaUploadService {
  MediaUploadService(this._storage);

  final FirebaseStorage _storage;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get uploadProgress => _progressController.stream;

  static const _maxRetries = 3;

  // Upload a list of image/video files and return their download URLs.
  Future<List<String>> uploadMedia(
    String mineId,
    String reportId,
    List<File> files,
  ) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final mime = _detectMime(file);
      _ensureAllowed(mime);

      final isVideo = mime.startsWith('video/');
      final ext = isVideo ? _videoExt(file.path) : '.jpg';
      final prefix = isVideo ? 'video' : 'image';
      final fileToUpload = isVideo ? file : (await _compressImage(file) ?? file);
      final ref = _storage.ref('reports/$mineId/$reportId/${prefix}_$i$ext');

      final url = await _uploadWithRetry(fileToUpload, ref, contentType: mime);
      urls.add(url);
    }
    return urls;
  }

  // Upload a voice note and return its download URL.
  Future<String> uploadVoiceNote(
    String mineId,
    String reportId,
    File audioFile,
  ) async {
    final mime = _detectMime(audioFile);
    if (!mime.startsWith('audio/')) {
      throw InvalidFileTypeException('Voice note must be audio/*, got "$mime"');
    }
    final ref = _storage.ref('reports/$mineId/$reportId/voice_note.aac');
    return _uploadWithRetry(audioFile, ref, contentType: mime);
  }

  void _ensureAllowed(String mime) {
    final ok = mime.startsWith('image/') ||
        mime.startsWith('video/') ||
        mime.startsWith('audio/');
    if (!ok) {
      throw InvalidFileTypeException('Unsupported MIME type: "$mime"');
    }
  }

  String _detectMime(File file) {
    final ext = _ext(file.path);
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      case '.aac':
      case '.m4a':
        return 'audio/aac';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  static String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot).toLowerCase() : '';
  }

  static String _videoExt(String path) {
    final ext = _ext(path);
    return ext.isNotEmpty ? ext : '.mp4';
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

  Future<String> _uploadWithRetry(
    File file,
    Reference ref, {
    required String contentType,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final task = ref.putFile(file, SettableMetadata(contentType: contentType));
        final sub = task.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          if (total > 0) {
            _progressController.add(snap.bytesTransferred / total);
          }
        });
        try {
          await task;
        } finally {
          await sub.cancel();
        }
        return await ref.getDownloadURL();
      } catch (e) {
        lastError = e;
        if (attempt == _maxRetries) break;
        // Exponential backoff: 1s, 2s, 4s
        final delaySec = 1 << (attempt - 1);
        await Future<void>.delayed(Duration(seconds: delaySec));
      }
    }
    throw MediaUploadException(
      'Upload failed after $_maxRetries attempts',
      cause: lastError,
    );
  }

  void dispose() => _progressController.close();
}
