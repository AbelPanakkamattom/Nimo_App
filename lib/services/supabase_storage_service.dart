import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseClient client =
      Supabase.instance.client;

  static const String bucket =
      'chat-files';

  /// =====================================
  /// 📛 GENERATE FILE NAME
  /// =====================================

  static String generateFileName(
      String extension,
      ) {
    final timestamp =
        DateTime.now()
            .millisecondsSinceEpoch;

    final random =
    Random.secure().nextInt(
      999999999,
    );

    return '${timestamp}_$random.$extension';
  }

  /// =====================================
  /// 📄 GET EXTENSION
  /// =====================================

  static String getExtension(
      File file,
      ) {
    final name =
        file.path.split('/').last;

    if (!name.contains('.')) {
      return 'jpg';
    }

    return name
        .split('.')
        .last
        .toLowerCase();
  }

  /// =====================================
  /// 🔐 VALIDATE FILE
  /// =====================================

  static void validateFile({
    required String extension,
    required String folder,
  }) {
    if (folder == 'images') {
      const allowed = [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
      ];

      if (!allowed.contains(
        extension,
      )) {
        throw Exception(
          'Invalid image format',
        );
      }
    }

    if (folder == 'audio') {
      const allowed = [
        'aac',
        'mp3',
        'wav',
        'm4a',
        'ogg',
      ];

      if (!allowed.contains(
        extension,
      )) {
        throw Exception(
          'Invalid audio format',
        );
      }
    }

    if (folder == 'videos') {
      const allowed = [
        'mp4',
        'mov',
        'avi',
        'mkv',
      ];

      if (!allowed.contains(
        extension,
      )) {
        throw Exception(
          'Invalid video format',
        );
      }
    }

    if (folder == 'documents') {
      const allowed = [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
      ];

      if (!allowed.contains(
        extension,
      )) {
        throw Exception(
          'Invalid document format',
        );
      }
    }
  }

  /// =====================================
  /// 🌐 MIME TYPE
  /// =====================================

  static String getMimeType({
    required String extension,
    required String folder,
  }) {
    if (folder == 'images') {
      return {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'gif': 'image/gif',
      }[extension] ??
          'image/jpeg';
    }

    if (folder == 'audio') {
      return {
        'aac': 'audio/aac',
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'm4a': 'audio/mp4',
        'ogg': 'audio/ogg',
      }[extension] ??
          'audio/mpeg';
    }

    if (folder == 'videos') {
      return {
        'mp4': 'video/mp4',
        'mov': 'video/quicktime',
        'avi': 'video/x-msvideo',
        'mkv': 'video/x-matroska',
      }[extension] ??
          'video/mp4';
    }

    if (folder == 'documents') {
      return {
        'pdf':
        'application/pdf',
        'doc':
        'application/msword',
        'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'ppt':
        'application/vnd.ms-powerpoint',
        'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'xls':
        'application/vnd.ms-excel',
        'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'txt': 'text/plain',
      }[extension] ??
          'application/octet-stream';
    }

    return 'application/octet-stream';
  }

  /// =====================================
  /// 🔗 PUBLIC URL
  /// =====================================

  static String getPublicUrl(
      String path,
      ) {
    return client.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  /// =====================================
  /// 📤 GENERIC UPLOAD
  /// =====================================

  static Future<String> uploadFile({
    required File file,
    required String folder,
  }) async {
    final user =
        client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    try {
      /// 📏 FILE SIZE
      final size =
      await file.length();

      /// 50MB LIMIT
      if (size >
          50 * 1024 * 1024) {
        throw Exception(
          'File too large (Max 50MB)',
        );
      }

      /// 📄 EXTENSION
      final extension =
      getExtension(file);

      /// 🔐 VALIDATE
      validateFile(
        extension: extension,
        folder: folder,
      );

      /// 📛 FILE NAME
      final fileName =
      generateFileName(
        extension,
      );

      /// 📁 STORAGE PATH
      final path =
          '${user.id}/$folder/$fileName';

      /// 📤 UPLOAD
      await client.storage
          .from(bucket)
          .upload(
        path,
        file,
        fileOptions:
        FileOptions(
          upsert: false,
          contentType:
          getMimeType(
            extension:
            extension,
            folder: folder,
          ),
        ),
      );

      /// 🔗 PUBLIC URL
      final url =
      getPublicUrl(path);

      /// 🔄 CACHE BREAKER
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      throw Exception(
        'Storage error: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Upload failed: $e',
      );
    }
  }

  /// =====================================
  /// 📸 IMAGE UPLOAD
  /// =====================================

  static Future<String>
  uploadImage(
      File file,
      ) async {
    return uploadFile(
      file: file,
      folder: 'images',
    );
  }

  /// =====================================
  /// 🎤 AUDIO UPLOAD
  /// =====================================

  static Future<String>
  uploadAudio(
      File file,
      ) async {
    return uploadFile(
      file: file,
      folder: 'audio',
    );
  }

  /// =====================================
  /// 🎥 VIDEO UPLOAD
  /// =====================================

  static Future<String>
  uploadVideo(
      File file,
      ) async {
    return uploadFile(
      file: file,
      folder: 'videos',
    );
  }

  /// =====================================
  /// 📄 DOCUMENT UPLOAD
  /// =====================================

  static Future<String>
  uploadDocument(
      File file,
      ) async {
    return uploadFile(
      file: file,
      folder: 'documents',
    );
  }

  /// =====================================
  /// 👤 PROFILE PHOTO
  /// =====================================

  static Future<String>
  uploadProfilePhoto(
      File file,
      ) async {
    return uploadFile(
      file: file,
      folder: 'profile',
    );
  }

  /// =====================================
  /// 🗑 DELETE FILE
  /// =====================================

  static Future<void> deleteFile(
      String url,
      ) async {
    try {
      final uri = Uri.parse(url);

      final cleanPath =
          uri.path.split('?').first;

      final segments =
      cleanPath.split('/');

      final bucketIndex =
      segments.indexOf(
        bucket,
      );

      if (bucketIndex == -1 ||
          bucketIndex + 1 >=
              segments.length) {
        throw Exception(
          'Invalid file path',
        );
      }

      final path = segments
          .sublist(
        bucketIndex + 1,
      )
          .join('/');

      await client.storage
          .from(bucket)
          .remove([path]);
    } on StorageException catch (e) {
      throw Exception(
        'Delete error: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Delete failed: $e',
      );
    }
  }

  /// =====================================
  /// 🧹 DELETE USER FILES
  /// =====================================

  static Future<void>
  deleteUserFiles() async {
    final user =
        client.auth.currentUser;

    if (user == null) return;

    try {
      final folders = [
        'images',
        'audio',
        'videos',
        'documents',
        'profile',
      ];

      for (final folder
      in folders) {
        final files = await client
            .storage
            .from(bucket)
            .list(
          path:
          '${user.id}/$folder',
        );

        final paths =
        files.map((file) {
          return '${user.id}/$folder/${file.name}';
        }).toList();

        if (paths.isNotEmpty) {
          await client.storage
              .from(bucket)
              .remove(paths);
        }
      }
    } catch (_) {}
  }
}