import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'supabase_chat_service.dart';

class ChatMediaService {
  ChatMediaService._();

  static final ImagePicker _picker = ImagePicker();

  // =========================================================
  // PICK IMAGE
  // =========================================================

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return null;
      return File(file.path);
    } catch (e) {
      debugPrint('Pick image error: $e');
      return null;
    }
  }

  // =========================================================
  // PICK VIDEO
  // =========================================================

  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (file == null) return null;
      return File(file.path);
    } catch (e) {
      debugPrint('Pick video error: $e');
      return null;
    }
  }

  // =========================================================
  // PICK DOCUMENT
  // =========================================================

  static Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'csv',
          'zip',
          'rar',
        ],
      );

      if (result == null) return null;

      final path = result.files.single.path;
      if (path == null) return null;

      return File(path);
    } catch (e) {
      debugPrint('Pick document error: $e');
      return null;
    }
  }

  // =========================================================
  // PICK AUDIO
  // =========================================================

  static Future<File?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'aac',
          'm4a',
          'ogg',
          'flac',
          'opus',
        ],
      );

      if (result == null) return null;

      final path = result.files.single.path;
      if (path == null) return null;

      return File(path);
    } catch (e) {
      debugPrint('Pick audio error: $e');
      return null;
    }
  }

  // =========================================================
  // SEND IMAGE
  // =========================================================

  static Future<void> sendImage({
    required String receiverId,
  }) async {
    try {
      final file = await pickImageFromGallery();
      if (file == null) return;

      final url = await SupabaseChatService.uploadFile(
        file: file,
        folder: 'images',
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: '',
        type: 'image',
        mediaUrl: url,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send image error: $e');
    }
  }

  // =========================================================
  // SEND VIDEO
  // =========================================================

  static Future<void> sendVideo({
    required String receiverId,
  }) async {
    try {
      final file = await pickVideoFromGallery();
      if (file == null) return;

      final url = await SupabaseChatService.uploadFile(
        file: file,
        folder: 'videos',
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: '',
        type: 'video',
        mediaUrl: url,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send video error: $e');
    }
  }

  // =========================================================
  // SEND DOCUMENT
  // =========================================================

  static Future<void> sendDocument({
    required String receiverId,
  }) async {
    try {
      final file = await pickDocument();
      if (file == null) return;

      final url = await SupabaseChatService.uploadFile(
        file: file,
        folder: 'documents',
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: 'Document',
        type: 'document',
        mediaUrl: url,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send document error: $e');
    }
  }

  // =========================================================
  // SEND AUDIO FILE
  // =========================================================

  static Future<void> sendAudio({
    required String receiverId,
  }) async {
    try {
      final file = await pickAudio();
      if (file == null) return;

      final url = await SupabaseChatService.uploadFile(
        file: file,
        folder: 'audio',
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: 'Audio',
        type: 'audio',
        mediaUrl: url,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send audio error: $e');
    }
  }

  // =========================================================
  // SEND VOICE MESSAGE
  // =========================================================

  static Future<void> sendVoiceMessage({
    required String receiverId,
    required File audioFile,
  }) async {
    try {
      final url = await SupabaseChatService.uploadFile(
        file: audioFile,
        folder: 'voice',
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: 'Voice Message',
        type: 'voice',
        mediaUrl: url,
        fileName: audioFile.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send voice error: $e');
    }
  }

  // =========================================================
  // SEND ANY FILE
  // =========================================================

  static Future<void> sendAnyFile({
    required String receiverId,
    required File file,
    required String folder,
    required String type,
  }) async {
    try {
      final url = await SupabaseChatService.uploadFile(
        file: file,
        folder: folder,
      );

      await SupabaseChatService.sendMessage(
        receiverId: receiverId,
        content: '',
        type: type,
        mediaUrl: url,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('Send file error: $e');
    }
  }

  // =========================================================
  // MEDIA PICKER
  // =========================================================

  static Future<File?> showMediaPicker(
      BuildContext context,
      ) async {
    return showModalBottomSheet<File>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              runSpacing: 12,
              children: [
                _buildOption(
                  icon: Icons.photo,
                  title: 'Image',
                  subtitle: 'Send image',
                  onTap: () async {
                    final file =
                    await pickImageFromGallery();
                    if (sheetContext.mounted) {
                      Navigator.pop(
                        sheetContext,
                        file,
                      );
                    }
                  },
                ),
                _buildOption(
                  icon: Icons.videocam,
                  title: 'Video',
                  subtitle: 'Send video',
                  onTap: () async {
                    final file =
                    await pickVideoFromGallery();
                    if (sheetContext.mounted) {
                      Navigator.pop(
                        sheetContext,
                        file,
                      );
                    }
                  },
                ),
                _buildOption(
                  icon:
                  Icons.insert_drive_file,
                  title: 'Document',
                  subtitle:
                  'Send document',
                  onTap: () async {
                    final file =
                    await pickDocument();
                    if (sheetContext.mounted) {
                      Navigator.pop(
                        sheetContext,
                        file,
                      );
                    }
                  },
                ),
                _buildOption(
                  icon: Icons.audiotrack,
                  title: 'Audio',
                  subtitle:
                  'Send audio file',
                  onTap: () async {
                    final file =
                    await pickAudio();
                    if (sheetContext.mounted) {
                      Navigator.pop(
                        sheetContext,
                        file,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // OPTION TILE
  // =========================================================

  static Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const Color primary =
    Color(0xFF6C5CE7);

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
          primary.withAlpha(20),
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        child: Icon(
          icon,
          color: primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight:
          FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
    );
  }
}