import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';
import '../services/supabase_chat_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/zego_call_service.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/profile_avatarz.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() =>
      _ChatDetailScreenState();
}

class _ChatDetailScreenState
    extends State<ChatDetailScreen> {
  static const Color primary =
  Color(0xFF6C5CE7);

  static const Color background =
  Color(0xFFF5F6FF);

  final TextEditingController
  _controller =
  TextEditingController();

  final ScrollController
  _scrollController =
  ScrollController();

  bool _isSending = false;

  // =========================================================
  // CURRENT USER
  // =========================================================

  String get _myUserId {
    return Supabase.instance.client.auth.currentUser?.id ??
        '';
  }

  String get _myUserName {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return 'NIMO User';
    }

    final metadata =
        user.userMetadata ?? {};

    final name =
        metadata['full_name'] ??
            metadata['display_name'] ??
            metadata['name'] ??
            metadata['username'] ??
            user.email
                ?.split('@')
                .first ??
            'NIMO User';

    return name.toString();
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    // Mark messages as seen
    SupabaseChatService.markAsSeen(
      widget.otherUserId,
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND TEXT MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {
    final text =
    _controller.text.trim();

    if (text.isEmpty ||
        _isSending) {
      return;
    }

    _controller.clear();

    try {
      await SupabaseChatService
          .sendMessage(
        receiverId:
        widget.otherUserId,
        content: text,
        type: 'text',
      );

      _scrollToBottom();
    } catch (_) {
      _showError(
        'Failed to send message',
      );
    }
  }

  // =========================================================
  // SEND IMAGE
  // =========================================================

  Future<void> _sendImage() async {
    try {
      final picker =
      ImagePicker();

      final image =
      await picker.pickImage(
        source:
        ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _isSending = true;
      });

      final url =
      await SupabaseStorageService
          .uploadChatMedia(
        file: File(image.path),
        bucket: 'message',
        folder: 'images',
      );

      await SupabaseChatService
          .sendMessage(
        receiverId:
        widget.otherUserId,
        content: '📷 Image',
        type: 'image',
        mediaUrl: url,
      );

      _scrollToBottom();
    } catch (_) {
      _showError(
        'Failed to send image',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =========================================================
  // SEND VIDEO
  // =========================================================

  Future<void> _sendVideo() async {
    try {
      final picker =
      ImagePicker();

      final video =
      await picker.pickVideo(
        source:
        ImageSource.gallery,
      );

      if (video == null) {
        return;
      }

      setState(() {
        _isSending = true;
      });

      final url =
      await SupabaseStorageService
          .uploadChatMedia(
        file: File(video.path),
        bucket: 'videos',
        folder: 'chat_videos',
      );

      await SupabaseChatService
          .sendMessage(
        receiverId:
        widget.otherUserId,
        content: '🎥 Video',
        type: 'video',
        mediaUrl: url,
      );

      _scrollToBottom();
    } catch (_) {
      _showError(
        'Failed to send video',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =========================================================
  // SEND DOCUMENT
  // =========================================================

  Future<void>
  _sendDocument() async {
    try {
      final result =
      await FilePicker
          .platform
          .pickFiles();

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final pickedFile =
          result.files.single;

      if (pickedFile.path ==
          null) {
        return;
      }

      setState(() {
        _isSending = true;
      });

      final url =
      await SupabaseStorageService
          .uploadChatMedia(
        file: File(
          pickedFile.path!,
        ),
        bucket: 'documents',
        folder: 'chat_docs',
      );

      await SupabaseChatService
          .sendMessage(
        receiverId:
        widget.otherUserId,
        content:
        pickedFile.name,
        type: 'document',
        mediaUrl: url,
        fileName:
        pickedFile.name,
      );

      _scrollToBottom();
    } catch (_) {
      _showError(
        'Failed to send document',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =========================================================
  // VOICE PLACEHOLDER
  // =========================================================

  void _showVoicePlaceholder() {
    _showError(
      'Voice recording support coming soon.',
    );
  }

  // =========================================================
  // ZEGO INITIALIZATION
  // =========================================================

  Future<void>
  _ensureZegoInitialized() async {
    if (_myUserId.isEmpty) {
      throw Exception(
        'User not logged in',
      );
    }

    if (!ZegoCallService
        .isInitialized) {
      await ZegoCallService.init(
        userID: _myUserId,
        userName: _myUserName,
      );
    }
  }

  // =========================================================
  // START VOICE CALL
  // =========================================================

  Future<void>
  _startVoiceCall() async {
    try {
      await _ensureZegoInitialized();

      await ZegoCallService
          .startVoiceCall(
        targetUserID:
        widget.otherUserId,
        targetUserName:
        widget.otherUserName,
      );
    } catch (e) {
      _showError(
        'Voice call failed: $e',
      );
    }
  }

  // =========================================================
  // START VIDEO CALL
  // =========================================================

  Future<void>
  _startVideoCall() async {
    try {
      await _ensureZegoInitialized();

      await ZegoCallService
          .startVideoCall(
        targetUserID:
        widget.otherUserId,
        targetUserName:
        widget.otherUserName,
      );
    } catch (e) {
      _showError(
        'Video call failed: $e',
      );
    }
  }

  // =========================================================
  // FORMAT DATE/TIME
  // =========================================================

  String _formatDateTime(
      DateTime dateTime,
      ) {
    return DateFormat(
      'd MMM, h:mm a',
    ).format(
      dateTime.toLocal(),
    );
  }

  // =========================================================
  // MESSAGE STATUS
  // =========================================================

  String _statusFor(
      Message message,
      ) {
    return message.status.name;
  }

  // =========================================================
  // CALL ICON
  // =========================================================

  IconData _callIcon(
      Message message,
      ) {
    if (message.isVideoCall) {
      return Icons.videocam;
    }

    return Icons.call;
  }

  // =========================================================
  // CALL BUBBLE
  // =========================================================

  Widget _buildCallBubble(
      Message message,
      ) {
    final isMe =
        message.senderId ==
            _myUserId;

    final bubbleColor =
    isMe
        ? primary
        : Colors.white;

    final textColor =
    isMe
        ? Colors.white
        : Colors.black87;

    final secondaryColor =
    isMe
        ? Colors.white70
        : Colors.grey.shade600;

    final description =
    message.callDescription(
      _myUserId,
    );

    String durationText = '';

    if (message.callDuration != null &&
        message.callDuration! > 0) {
      final duration =
      Duration(
        seconds:
        message.callDuration!,
      );

      final minutes = duration
          .inMinutes
          .toString()
          .padLeft(2, '0');

      final seconds =
      (duration.inSeconds % 60)
          .toString()
          .padLeft(2, '0');

      durationText =
      '$minutes:$seconds';
    }

    return Align(
      alignment:
      isMe
          ? Alignment
          .centerRight
          : Alignment
          .centerLeft,
      child: Container(
        margin:
        const EdgeInsets
            .symmetric(
          vertical: 6,
        ),
        padding:
        const EdgeInsets
            .all(12),
        constraints:
        BoxConstraints(
          maxWidth:
          MediaQuery.of(
            context,
          )
              .size
              .width *
              0.75,
        ),
        decoration:
        BoxDecoration(
          color:
          bubbleColor,
          borderRadius:
          BorderRadius
              .circular(
            22,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors
                  .black
                  .withValues(
                alpha: 0.06,
              ),
              blurRadius:
              8,
              offset:
              const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  _callIcon(
                    message,
                  ),
                  color: message
                      .isMissedCall
                      ? Colors
                      .redAccent
                      : (isMe
                      ? Colors
                      .white
                      : primary),
                  size: 22,
                ),
                const SizedBox(
                  width: 8,
                ),
                Flexible(
                  child: Text(
                    description,
                    style:
                    TextStyle(
                      color:
                      textColor,
                      fontSize:
                      15,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ],
            ),
            if (durationText
                .isNotEmpty) ...[
              const SizedBox(
                height: 4,
              ),
              Text(
                durationText,
                style:
                TextStyle(
                  color:
                  secondaryColor,
                  fontSize:
                  12,
                ),
              ),
            ],
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  _formatDateTime(
                    message
                        .createdAt,
                  ),
                  style:
                  TextStyle(
                    fontSize:
                    11,
                    color:
                    secondaryColor,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(
                    width: 4,
                  ),
                  Icon(
                    Icons
                        .done_all,
                    size: 16,
                    color: message
                        .isSeen
                        ? const Color(
                      0xFFFFD700,
                    )
                        : Colors
                        .white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MESSAGE BUBBLE
  // =========================================================

  Widget _buildMessageBubble(
      Message message,
      ) {
    // Show special call bubble
    if (message.isAnyCall) {
      return _buildCallBubble(
        message,
      );
    }

    final isMe =
        message.senderId ==
            _myUserId;

    final mediaUrl =
        message.mediaUrl ?? '';

    final displayMessage =
    message.type ==
        MessageType.text
        ? message.content
        : (mediaUrl
        .isNotEmpty
        ? mediaUrl
        : message
        .content);

    return MessageBubble(
      message:
      displayMessage,
      time: _formatDateTime(
        message.createdAt,
      ),
      isMe: isMe,
      isImage:
      message.type ==
          MessageType.image,
      isAudio:
      message.type ==
          MessageType.audio,
      isDocument:
      message.type ==
          MessageType
              .document,
      isVideo:
      message.type ==
          MessageType.video,
      status:
      _statusFor(message),
      fileName:
      message.fileName,
    );
  }

  // =========================================================
  // AUTO SCROLL
  // =========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (!_scrollController
          .hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration:
        const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // =========================================================
  // SHOW ERROR
  // =========================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        behavior:
        SnackBarBehavior
            .floating,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      background,
      resizeToAvoidBottomInset:
      true,
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        foregroundColor:
        Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              name: widget
                  .otherUserName,
              imageUrl: widget
                  .otherUserAvatar,
              radius: 20,
              isOnline: true,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Text(
                    widget
                        .otherUserName,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight
                          .bold,
                      fontSize:
                      16,
                    ),
                  ),
                  const Text(
                    'Online',
                    style:
                    TextStyle(
                      color:
                      Colors
                          .green,
                      fontSize:
                      12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed:
            _startVoiceCall,
            icon:
            const Icon(
              Icons.call,
            ),
          ),
          IconButton(
            onPressed:
            _startVideoCall,
            icon:
            const Icon(
              Icons.videocam,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                List<Message>>(
              stream:
              SupabaseChatService
                  .getChat(
                widget
                    .otherUserId,
              ),
              builder: (
                  context,
                  snapshot,
                  ) {
                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color:
                      primary,
                    ),
                  );
                }

                final messages =
                    snapshot.data ??
                        [];

                if (messages
                    .isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                    ),
                  );
                }

                WidgetsBinding
                    .instance
                    .addPostFrameCallback(
                      (_) =>
                      _scrollToBottom(),
                );

                return ListView.builder(
                  controller:
                  _scrollController,
                  padding:
                  const EdgeInsets
                      .all(14),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
                  itemCount:
                  messages
                      .length,
                  itemBuilder: (
                      context,
                      index,
                      ) {
                    return _buildMessageBubble(
                      messages[
                      index],
                    );
                  },
                );
              },
            ),
          ),
          ChatInputWidget(
            controller:
            _controller,
            isSending:
            _isSending,
            onSend:
            _sendMessage,
            onImage:
            _sendImage,
            onDocument:
            _sendDocument,
            onVideo:
            _sendVideo,
            onVoice:
            _showVoicePlaceholder,
            onTyping: (
                text,
                ) {
              // Optional typing indicator
            },
          ),
        ],
      ),
    );
  }
}