import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  static final SupabaseClient client =
      Supabase.instance.client;

  // =========================================================
  // AUTH HELPERS
  // =========================================================

  static User? get currentUser =>
      client.auth.currentUser;

  static String get myId =>
      currentUser?.id ?? '';

  static bool get isLoggedIn =>
      currentUser != null &&
          myId.isNotEmpty;

  static void _ensureLoggedIn() {
    if (!isLoggedIn) {
      throw Exception('User not logged in.');
    }
  }

  // =========================================================
  // BUCKET NAMES
  // =========================================================

  static const String profileBucket = 'avatarz';
  static const String imageBucket = 'message';
  static const String audioBucket = 'audio';
  static const String videoBucket = 'videos';
  static const String documentBucket =
      'documents';

  // =========================================================
  // MAX FILE SIZE (50 MB)
  // =========================================================

  static const int maxFileSize =
      50 * 1024 * 1024;

  // =========================================================
  // EXTENSION GROUPS
  // =========================================================

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
  };

  static const Set<String> _audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'opus',
    'amr',
    '3gp',
    'webm',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    '3gp',
  };

  static const Set<String> _documentExtensions = {
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'txt',
    'csv',
    'json',
    'xml',
    'zip',
    'rar',
    '7z',
    'apk',
    'dart',
    'java',
    'kt',
    'js',
    'ts',
    'html',
    'css',
    'py',
    'cpp',
    'c',
    'h',
  };

  // =========================================================
  // BASIC HELPERS
  // =========================================================

  static String getExtension(File file) {
    final extension = path
        .extension(file.path)
        .replaceFirst('.', '')
        .toLowerCase();

    return extension.isEmpty ? 'bin' : extension;
  }

  static Future<void> _ensureFileExists(
      File file,
      ) async {
    final exists = await file.exists();

    if (!exists) {
      throw Exception('File does not exist.');
    }
  }

  static Future<void> _validateSize(
      File file,
      ) async {
    final size = await file.length();

    if (size > maxFileSize) {
      throw Exception(
        'File is larger than 50 MB.',
      );
    }
  }

  static String _generateFileName(
      String extension,
      ) {
    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final random =
    Random.secure().nextInt(999999999);

    return '${timestamp}_$random.$extension';
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  static void _validateExtension({
    required String extension,
    required String folder,
  }) {
    Set<String> allowed;

    switch (folder) {
      case 'profile':
      case 'images':
        allowed = _imageExtensions;
        break;

      case 'audio':
        allowed = _audioExtensions;
        break;

      case 'videos':
        allowed = _videoExtensions;
        break;

      case 'documents':
        allowed = _documentExtensions;
        break;

      default:
        throw Exception(
          'Unknown folder: $folder',
        );
    }

    if (!allowed.contains(extension)) {
      throw Exception(
        'Unsupported .$extension file.',
      );
    }
  }

  // =========================================================
  // FOLDER -> BUCKET
  // =========================================================

  static String _bucketForFolder(
      String folder,
      ) {
    switch (folder) {
      case 'profile':
        return profileBucket;
      case 'images':
        return imageBucket;
      case 'audio':
        return audioBucket;
      case 'videos':
        return videoBucket;
      case 'documents':
        return documentBucket;
      default:
        throw Exception(
          'Unknown folder: $folder',
        );
    }
  }

  // =========================================================
  // MIME TYPES
  // =========================================================

  static String _mimeType(
      String extension,
      ) {
    const map = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };

    return map[extension] ??
        'application/octet-stream';
  }

  // =========================================================
  // PUBLIC URL
  // =========================================================

  static String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return client.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  // =========================================================
  // MAIN UPLOAD
  // =========================================================

  static Future<String> uploadFile({
    required File file,
    required String folder,
  }) async {
    _ensureLoggedIn();

    await _ensureFileExists(file);
    await _validateSize(file);

    final extension = getExtension(file);

    _validateExtension(
      extension: extension,
      folder: folder,
    );

    final bucket = _bucketForFolder(folder);
    final fileName =
    _generateFileName(extension);

    final storagePath =
        '$myId/$folder/$fileName';

    final contentType =
    _mimeType(extension);

    try {
      debugPrint(
        'Uploading to $bucket/$storagePath',
      );

      await client.storage
          .from(bucket)
          .upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      final url = getPublicUrl(
        bucket: bucket,
        path: storagePath,
      );

      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      debugPrint(
        'UPLOAD ERROR: ${e.message}',
      );

      throw Exception(
        'Upload failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      throw Exception('Upload failed.');
    }
  }

  // =========================================================
  // CHAT MEDIA UPLOAD
  // Used by ChatDetailScreen
  // =========================================================

  static Future<String> uploadChatMedia({
    required File file,
    required String bucket,
    String? folder,
  }) async {
    _ensureLoggedIn();

    await _ensureFileExists(file);
    await _validateSize(file);

    final extension = getExtension(file);

    // Determine logical folder
    String logicalFolder;

    switch (bucket) {
      case profileBucket:
        logicalFolder = 'profile';
        break;
      case imageBucket:
        logicalFolder = 'images';
        break;
      case audioBucket:
        logicalFolder = 'audio';
        break;
      case videoBucket:
        logicalFolder = 'videos';
        break;
      case documentBucket:
        logicalFolder = 'documents';
        break;
      default:
        throw Exception(
          'Unknown bucket: $bucket',
        );
    }

    _validateExtension(
      extension: extension,
      folder: logicalFolder,
    );

    final fileName =
    _generateFileName(extension);

    final subfolder =
    (folder != null &&
        folder.trim().isNotEmpty)
        ? folder.trim()
        : logicalFolder;

    final storagePath =
        '$myId/$subfolder/$fileName';

    final contentType =
    _mimeType(extension);

    try {
      debugPrint(
        'Uploading to $bucket/$storagePath',
      );

      await client.storage
          .from(bucket)
          .upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      final url = client.storage
          .from(bucket)
          .getPublicUrl(storagePath);

      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      debugPrint(
        'CHAT MEDIA ERROR: ${e.message}',
      );

      throw Exception(
        'Upload failed: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'CHAT MEDIA ERROR: $e',
      );

      throw Exception('Upload failed.');
    }
  }

  // =========================================================
  // CONVENIENCE METHODS
  // =========================================================

  static Future<String> uploadProfilePhoto(
      File file,
      ) {
    return uploadFile(
      file: file,
      folder: 'profile',
    );
  }

  static Future<String> uploadImage(
      File file,
      ) {
    return uploadFile(
      file: file,
      folder: 'images',
    );
  }

  static Future<String> uploadAudio(
      File file,
      ) {
    return uploadFile(
      file: file,
      folder: 'audio',
    );
  }

  static Future<String> uploadVideo(
      File file,
      ) {
    return uploadFile(
      file: file,
      folder: 'videos',
    );
  }

  static Future<String> uploadDocument(
      File file,
      ) {
    return uploadFile(
      file: file,
      folder: 'documents',
    );
  }

  // =========================================================
  // DELETE FILE
  // =========================================================

  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage
          .from(bucket)
          .remove([path]);
    } on StorageException catch (e) {
      throw Exception(
        'Delete failed: ${e.message}',
      );
    } catch (_) {
      throw Exception('Delete failed.');
    }
  }

  // =========================================================
  // EXTRACT STORAGE PATH FROM URL
  // =========================================================

  static String? extractPathFromUrl(
      String url,
      ) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      final objectIndex =
      segments.indexOf('object');

      if (objectIndex == -1 ||
          objectIndex + 2 >=
              segments.length) {
        return null;
      }

      return segments
          .sublist(objectIndex + 2)
          .join('/');
    } catch (_) {
      return null;
    }
  }
}