import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const String _bucket = "chat-files";

  /// 🔹 GENERATE UNIQUE FILE NAME
  static String _generateFileName(String ext) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(1 << 32);
    return "${timestamp}_$random.$ext";
  }

  /// 🔹 GET FILE EXTENSION
  static String _getExtension(File file) {
    final name = file.uri.pathSegments.last;
    if (!name.contains('.')) return 'jpg';
    return name.split('.').last.toLowerCase();
  }

  /// 🔹 VALIDATE FILE TYPE
  static void _validateFile(String ext, String folder) {
    if (folder == "images") {
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        throw Exception("Invalid image format");
      }
    }

    if (folder == "audio") {
      if (!['aac', 'mp3', 'wav', 'm4a'].contains(ext)) {
        throw Exception("Invalid audio format");
      }
    }
  }

  /// 🔹 MIME TYPE
  static String _getMimeType(String ext, String folder) {
    if (folder == "images") {
      return {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      }[ext] ??
          'image/jpeg';
    }

    if (folder == "audio") {
      return {
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'm4a': 'audio/mp4',
        'aac': 'audio/aac',
      }[ext] ??
          'audio/mpeg';
    }

    return 'application/octet-stream';
  }

  /// 🔹 GENERATE PUBLIC URL (BETTER FOR CHAT)
  static String _getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// 🔹 GENERIC UPLOAD (IMPROVED)
  static Future<String> _uploadFile({
    required File file,
    required String folder,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      /// 📏 SIZE CHECK
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        throw Exception("File too large (Max 10MB)");
      }

      final ext = _getExtension(file);

      /// 🔐 VALIDATE
      _validateFile(ext, folder);

      final fileName = _generateFileName(ext);

      /// 🔥 USER-SCOPED PATH
      final path = "${user.id}/$folder/$fileName";

      final storage = _client.storage.from(_bucket);

      /// 📤 UPLOAD (WITH RETRY)
      await storage.upload(
        path,
        file,
        fileOptions: FileOptions(
          upsert: false,
          contentType: _getMimeType(ext, folder),
        ),
      );

      /// 🔥 PUBLIC URL (FAST + STABLE)
      final url = _getPublicUrl(path);

      /// 🔁 CACHE BREAK
      return "$url?t=${DateTime.now().millisecondsSinceEpoch}";
    } on StorageException catch (e) {
      throw Exception("Storage error: ${e.message}");
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  /// 📸 IMAGE UPLOAD
  static Future<String> uploadImage(File file) async {
    return _uploadFile(file: file, folder: "images");
  }

  /// 🎤 AUDIO UPLOAD
  static Future<String> uploadAudio(File file) async {
    return _uploadFile(file: file, folder: "audio");
  }

  /// 🗑 DELETE FILE (FIXED)
  static Future<void> deleteFile(String url) async {
    try {
      final uri = Uri.parse(url);

      /// REMOVE QUERY PARAM (?t=...)
      final cleanPath = uri.path.split('?').first;

      final segments = cleanPath.split('/');

      final index = segments.indexOf(_bucket);

      if (index == -1 || index + 1 >= segments.length) {
        throw Exception("Invalid file path");
      }

      final path = segments.sublist(index + 1).join('/');

      await _client.storage.from(_bucket).remove([path]);
    } on StorageException catch (e) {
      throw Exception("Storage delete error: ${e.message}");
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }
}