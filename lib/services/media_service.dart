import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  static final SupabaseClient supabase =
      Supabase.instance.client;

  /// =========================
  /// PICK IMAGE
  /// =========================

  static Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();

      final picked =
      await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) {
        return null;
      }

      return File(picked.path);
    } catch (e) {
      debugPrint(
        "PICK IMAGE ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// PICK DOCUMENT
  /// =========================

  static Future<File?> pickDocument()
  async {
    try {
      final result =
      await FilePicker.platform
          .pickFiles();

      if (result == null ||
          result.files.isEmpty) {
        return null;
      }

      final filePath =
          result.files.single.path;

      if (filePath == null) {
        return null;
      }

      return File(filePath);
    } catch (e) {
      debugPrint(
        "PICK DOCUMENT ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// UPLOAD IMAGE
  /// =========================

  static Future<String?> uploadImage(
      File file,
      ) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      await supabase.storage
          .from('message')
          .upload(
        fileName,
        file,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final url = supabase.storage
          .from('message')
          .getPublicUrl(
        fileName,
      );

      return url;
    } catch (e) {
      debugPrint(
        "UPLOAD IMAGE ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// UPLOAD AUDIO
  /// =========================

  static Future<String?> uploadAudio(
      File file,
      ) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      await supabase.storage
          .from('audio')
          .upload(
        fileName,
        file,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final url = supabase.storage
          .from('audio')
          .getPublicUrl(
        fileName,
      );

      return url;
    } catch (e) {
      debugPrint(
        "UPLOAD AUDIO ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// UPLOAD DOCUMENT
  /// =========================

  static Future<String?> uploadDocument(
      File file,
      ) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";

      await supabase.storage
          .from('documents')
          .upload(
        fileName,
        file,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final url = supabase.storage
          .from('documents')
          .getPublicUrl(
        fileName,
      );

      return url;
    } catch (e) {
      debugPrint(
        "UPLOAD DOCUMENT ERROR: $e",
      );

      return null;
    }
  }

  /// =========================
  /// DELETE FILE
  /// =========================

  static Future<bool> deleteFile({
    required String bucket,
    required String pathName,
  }) async {
    try {
      await supabase.storage
          .from(bucket)
          .remove([
        pathName,
      ]);

      return true;
    } catch (e) {
      debugPrint(
        "DELETE FILE ERROR: $e",
      );

      return false;
    }
  }

  /// =========================
  /// FILE TYPES
  /// =========================

  static bool isImage(
      String url,
      ) {
    final lower =
    url.toLowerCase();

    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  static bool isAudio(
      String url,
      ) {
    final lower =
    url.toLowerCase();

    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav');
  }

  static bool isDocument(
      String url,
      ) {
    final lower =
    url.toLowerCase();

    return lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.txt');
  }

  /// =========================
  /// FILE NAME
  /// =========================

  static String getFileName(
      String url,
      ) {
    try {
      return path.basename(url);
    } catch (_) {
      return "File";
    }
  }

  /// =========================
  /// FILE SIZE
  /// =========================

  static Future<String> getFileSize(
      File file,
      ) async {
    try {
      final bytes =
      await file.length();

      if (bytes < 1024) {
        return "$bytes B";
      }

      if (bytes <
          1024 * 1024) {
        return "${(bytes / 1024).toStringAsFixed(1)} KB";
      }

      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } catch (_) {
      return "";
    }
  }
}