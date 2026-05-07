import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ChatInputWidget
    extends StatefulWidget {
  final Future<void> Function(
      String message,
      ) onSendMessage;

  final Future<void> Function(
      File image,
      )? onSendImage;

  final Future<void> Function(
      File audio,
      )? onSendAudio;

  final Function(String value)?
  onTyping;

  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
    this.onSendAudio,
    this.onTyping,
  });

  @override
  State<ChatInputWidget>
  createState() =>
      _ChatInputWidgetState();
}

class _ChatInputWidgetState
    extends State<ChatInputWidget> {
  final TextEditingController
  controller =
  TextEditingController();

  final AudioRecorder recorder =
  AudioRecorder();

  bool recording = false;
  bool sending = false;

  /// =========================
  /// SEND MESSAGE
  /// =========================

  Future<void> sendMessage() async {
    final text =
    controller.text.trim();

    if (text.isEmpty ||
        sending) {
      return;
    }

    setState(() {
      sending = true;
    });

    controller.clear();

    try {
      await widget.onSendMessage(
        text,
      );
    } catch (e) {
      debugPrint(
        "SEND MESSAGE ERROR: $e",
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      sending = false;
    });
  }

  /// =========================
  /// PICK IMAGE
  /// =========================

  Future<void> pickImage()
  async {
    try {
      final permission =
      await Permission.photos
          .request();

      if (!permission.isGranted) {
        return;
      }

      final picker =
      ImagePicker();

      final picked =
      await picker.pickImage(
        source:
        ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) {
        return;
      }

      final file =
      File(picked.path);

      if (widget.onSendImage !=
          null) {
        await widget.onSendImage!(
          file,
        );
      }
    } catch (e) {
      debugPrint(
        "IMAGE PICK ERROR: $e",
      );
    }
  }

  /// =========================
  /// RECORD AUDIO
  /// =========================

  Future<void>
  toggleRecording() async {
    try {
      if (!recording) {
        final micPermission =
        await Permission
            .microphone
            .request();

        if (!micPermission
            .isGranted) {
          return;
        }

        final tempDir =
            Directory.systemTemp;

        final audioPath =
            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

        await recorder.start(
          const RecordConfig(),
          path: audioPath,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          recording = true;
        });

        return;
      }

      final path =
      await recorder.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        recording = false;
      });

      if (path == null) {
        return;
      }

      final file =
      File(path);

      if (widget.onSendAudio !=
          null) {
        await widget.onSendAudio!(
          file,
        );
      }
    } catch (e) {
      debugPrint(
        "AUDIO ERROR: $e",
      );
    }
  }

  /// =========================
  /// BUILD
  /// =========================

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      child: Container(
        padding:
        const EdgeInsets.all(
          10,
        ),

        decoration:
        const BoxDecoration(
          color: Colors.white,
        ),

        child: Row(
          children: [
            /// IMAGE
            IconButton(
              onPressed:
              sending
                  ? null
                  : pickImage,

              icon: const Icon(
                Icons.image,
                color: Color(
                  0xFF6C5CE7,
                ),
              ),
            ),

            /// MIC
            IconButton(
              onPressed:
              sending
                  ? null
                  : toggleRecording,

              icon: Icon(
                recording
                    ? Icons.stop
                    : Icons.mic,

                color:
                recording
                    ? Colors.red
                    : const Color(
                  0xFF6C5CE7,
                ),
              ),
            ),

            /// TEXT FIELD
            Expanded(
              child: TextField(
                controller:
                controller,

                minLines: 1,
                maxLines: 5,

                onChanged:
                widget.onTyping,

                decoration:
                InputDecoration(
                  hintText:
                  "Type message...",

                  filled: true,

                  fillColor:
                  const Color(
                    0xFFF5F6FF,
                  ),

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),

                    borderSide:
                    BorderSide.none,
                  ),

                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            /// SEND BUTTON
            GestureDetector(
              onTap:
              sending
                  ? null
                  : sendMessage,

              child: Container(
                width: 52,
                height: 52,

                decoration:
                const BoxDecoration(
                  color: Color(
                    0xFF6C5CE7,
                  ),

                  shape:
                  BoxShape.circle,
                ),

                child: sending
                    ? const Padding(
                  padding:
                  EdgeInsets.all(
                    14,
                  ),

                  child:
                  CircularProgressIndicator(
                    color:
                    Colors.white,
                    strokeWidth:
                    2,
                  ),
                )
                    : const Icon(
                  Icons.send,
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    recorder.dispose();

    super.dispose();
  }
}