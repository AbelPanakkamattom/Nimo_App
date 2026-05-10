import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'message_status_icon.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final String time;
  final bool isMe;

  final bool isImage;
  final bool isAudio;
  final bool isDocument;
  final bool isVideo;

  /// sent, delivered, seen, failed, sending
  final String status;

  final String? fileName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    this.isMe = false,
    this.isImage = false,
    this.isAudio = false,
    this.isDocument = false,
    this.isVideo = false,
    this.status = 'sent',
    this.fileName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  static const Color primary = Color(0xFF6C5CE7);

  AudioPlayer? _player;

  bool _playing = false;
  bool _loadingAudio = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    if (widget.isAudio) {
      _initializeAudio();
    }
  }

  Future<void> _initializeAudio() async {
    try {
      _player = AudioPlayer();

      _player!.durationStream.listen((value) {
        if (!mounted) return;
        setState(() {
          _duration = value ?? Duration.zero;
        });
      });

      _player!.positionStream.listen((value) {
        if (!mounted) return;
        setState(() {
          _position = value;
        });
      });

      _player!.playerStateStream.listen((state) {
        if (!mounted) return;

        setState(() {
          _playing = state.playing;

          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
            _playing = false;
          }
        });
      });
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  // =========================================================
  // OPEN URL
  // =========================================================

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) return;

    try {
      final uri = Uri.parse(url.trim());

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open file'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open file'),
        ),
      );
    }
  }

  // =========================================================
  // AUDIO PLAYBACK
  // =========================================================

  Future<void> _toggleAudio() async {
    if (_player == null) return;

    try {
      if (_playing) {
        await _player!.pause();
        return;
      }

      setState(() {
        _loadingAudio = true;
      });

      if (_duration == Duration.zero) {
        await _player!.setUrl(widget.message);
      }

      if (!mounted) return;

      setState(() {
        _loadingAudio = false;
      });

      await _player!.play();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingAudio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play audio'),
        ),
      );
    }
  }

  // =========================================================
  // FORMAT DURATION
  // =========================================================

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds =
    value.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // =========================================================
  // IMAGE MESSAGE
  // =========================================================

  Widget _buildImageMessage() {
    return GestureDetector(
      onTap: () => _openUrl(widget.message),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.message,
          width: 240,
          height: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 240,
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 240,
            height: 300,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // AUDIO MESSAGE
  // =========================================================

  Widget _buildAudioMessage() {
    final textColor =
    widget.isMe ? Colors.white : Colors.black87;

    return SizedBox(
      width: 240,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleAudio,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white24 : primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _loadingAudio
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  _playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape:
                    SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1,
                    value: _position.inMilliseconds
                        .clamp(
                      0,
                      _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds
                          : 1,
                    )
                        .toDouble(),
                    activeColor: widget.isMe
                        ? Colors.white
                        : primary,
                    inactiveColor:
                    textColor.withValues(alpha: 0.3),
                    onChanged: (value) async {
                      if (_player == null) return;

                      await _player!.seek(
                        Duration(
                          milliseconds: value.toInt(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.only(left: 4),
                  child: Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color:
                      textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DOCUMENT MESSAGE
  // =========================================================

  Widget _buildDocumentMessage() {
    final textColor =
    widget.isMe ? Colors.white : Colors.black87;

    final title = (widget.fileName != null &&
        widget.fileName!.trim().isNotEmpty)
        ? widget.fileName!.trim()
        : 'Open Document';

    return GestureDetector(
      onTap: () => _openUrl(widget.message),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: widget.isMe
              ? Colors.white24
              : const Color(0xFFF3F2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              color: textColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // VIDEO MESSAGE
  // =========================================================

  Widget _buildVideoMessage() {
    final textColor =
    widget.isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () => _openUrl(widget.message),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: widget.isMe
              ? Colors.white24
              : const Color(0xFFF3F2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.videocam,
              color: textColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Open Video',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TEXT MESSAGE
  // =========================================================

  Widget _buildTextMessage() {
    final textColor =
    widget.isMe ? Colors.white : Colors.black87;

    final message = widget.message.trim();

    final isUrl = message.startsWith('http://') ||
        message.startsWith('https://');

    return GestureDetector(
      onTap: isUrl ? () => _openUrl(message) : null,
      child: Text(
        message,
        style: TextStyle(
          color: isUrl
              ? (widget.isMe
              ? Colors.white
              : Colors.blue)
              : textColor,
          fontSize: 15,
          height: 1.4,
          decoration: isUrl
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent() {
    if (widget.isImage) return _buildImageMessage();
    if (widget.isAudio) return _buildAudioMessage();
    if (widget.isDocument) return _buildDocumentMessage();
    if (widget.isVideo) return _buildVideoMessage();
    return _buildTextMessage();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Container(
          constraints:
          const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isMe
                ? primary
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(
                widget.isMe ? 20 : 6,
              ),
              bottomRight: Radius.circular(
                widget.isMe ? 6 : 20,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              _buildContent(),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.time,
                    style: TextStyle(
                      color: widget.isMe
                          ? Colors.white70
                          : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  if (widget.isMe) ...[
                    const SizedBox(width: 5),
                    MessageStatusIcon(
                      status: widget.status,
                      size: 16,
                      isMe: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}