import 'package:flutter/material.dart';

class ChatInputWidget extends StatelessWidget {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  final TextEditingController controller;
  final bool isSending;

  /// Send text message
  final Future<void> Function() onSend;

  /// Pick and send image
  final Future<void> Function()? onImage;

  /// Pick and send document
  final Future<void> Function()? onDocument;

  /// Pick and send video
  final Future<void> Function()? onVideo;

  /// Pick and send audio file
  final Future<void> Function()? onAudio;

  /// Voice recording / placeholder
  final VoidCallback? onVoice;

  /// Typing callback
  final ValueChanged<String>? onTyping;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.onImage,
    this.onDocument,
    this.onVideo,
    this.onAudio,
    this.onVoice,
    this.onTyping,
  });

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'Type a message...',
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 15,
      ),
      filled: true,
      fillColor: background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    );
  }

  // ==========================================================
  // ATTACHMENT BUTTON
  // ==========================================================

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      splashRadius: 22,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: isSending ? null : onPressed,
      icon: Icon(
        icon,
        color: primary,
        size: 24,
      ),
    );
  }

  // ==========================================================
  // SEND BUTTON
  // ==========================================================

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: isSending ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF8E7BFF),
              primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withAlpha(70),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isSending
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.2,
            ),
          )
              : const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              // Image
              if (onImage != null)
                _buildIconButton(
                  icon: Icons.image_outlined,
                  tooltip: 'Image',
                  onPressed: () => onImage!(),
                ),

              // Document
              if (onDocument != null)
                _buildIconButton(
                  icon: Icons.attach_file,
                  tooltip: 'Document',
                  onPressed: () => onDocument!(),
                ),

              // Video
              if (onVideo != null)
                _buildIconButton(
                  icon:
                  Icons.videocam_outlined,
                  tooltip: 'Video',
                  onPressed: () => onVideo!(),
                ),

              // Audio
              if (onAudio != null)
                _buildIconButton(
                  icon:
                  Icons.audiotrack_rounded,
                  tooltip: 'Audio',
                  onPressed: () => onAudio!(),
                ),

              // Voice
              if (onVoice != null)
                _buildIconButton(
                  icon:
                  Icons.mic_none_rounded,
                  tooltip: 'Voice',
                  onPressed: onVoice,
                ),

              // Text Field
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType:
                  TextInputType.multiline,
                  textInputAction:
                  TextInputAction
                      .newline,
                  onChanged: onTyping,
                  decoration:
                  _inputDecoration(),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }
}