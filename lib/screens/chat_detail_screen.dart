import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message_model.dart';
import '../services/chat_media_service.dart';
import '../services/supabase_chat_service.dart';
import '../services/zego_call_service.dart';
import '../utils/chat_error_helper.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_message_list.dart';

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
  static const Color background =
  Color(0xFFF5F6FF);

  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  bool _isSending = false;

  // =========================================================
  // CURRENT USER
  // =========================================================

  String get _myUserId {
    return Supabase
        .instance
        .client
        .auth
        .currentUser
        ?.id ??
        '';
  }

  String get _myUserName {
    final user = Supabase
        .instance
        .client
        .auth
        .currentUser;

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

    if (text.isEmpty || _isSending) {
      return;
    }

    _controller.clear();

    try {
      await SupabaseChatService.sendMessage(
        receiverId:
        widget.otherUserId,
        content: text,
        type: 'text',
      );

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      ChatErrorHelper.showError(
        context,
        'Failed to send message',
      );
    }
  }

  // =========================================================
  // SEND IMAGE
  // =========================================================

  Future<void> _sendImage() async {
    await _runSendingTask(() async {
      await ChatMediaService.sendImage(
        receiverId:
        widget.otherUserId,
      );
    });
  }

  // =========================================================
  // SEND VIDEO
  // =========================================================

  Future<void> _sendVideo() async {
    await _runSendingTask(() async {
      await ChatMediaService.sendVideo(
        receiverId:
        widget.otherUserId,
      );
    });
  }

  // =========================================================
  // SEND DOCUMENT
  // =========================================================

  Future<void> _sendDocument() async {
    await _runSendingTask(() async {
      await ChatMediaService.sendDocument(
        receiverId:
        widget.otherUserId,
      );
    });
  }

  // =========================================================
  // SEND AUDIO FILE
  // =========================================================

  Future<void> _sendAudio() async {
    await _runSendingTask(() async {
      await ChatMediaService.sendAudio(
        receiverId:
        widget.otherUserId,
      );
    });
  }

  // =========================================================
  // SEND VOICE MESSAGE
  // =========================================================

  Future<void> _sendVoiceMessage() async {
    // For now, reuse audio picker.
    // When your recorder saves a file,
    // call ChatMediaService.sendVoiceMessage(...)
    await _sendAudio();
  }

  // =========================================================
  // FILE SENDING WRAPPER
  // =========================================================

  Future<void> _runSendingTask(
      Future<void> Function() task,
      ) async {
    if (_isSending) {
      return;
    }

    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      await task();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ChatErrorHelper.showError(
        context,
        'Failed to send file',
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
      if (!mounted) return;

      ChatErrorHelper.showError(
        context,
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
      if (!mounted) return;

      ChatErrorHelper.showError(
        context,
        'Video call failed: $e',
      );
    }
  }

  // =========================================================
  // AUTO SCROLL
  // =========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

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
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
      background,
      resizeToAvoidBottomInset:
      true,
      appBar: ChatAppBar(
        otherUserName:
        widget.otherUserName,
        otherUserAvatar:
        widget.otherUserAvatar,
        onVoiceCall:
        _startVoiceCall,
        onVideoCall:
        _startVideoCall,
        isOnline: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                List<Message>>(
              stream:
              SupabaseChatService
                  .getChat(
                widget.otherUserId,
              ),
              builder: (
                  context,
                  snapshot,
                  ) {
                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data ??
                        [];

                WidgetsBinding
                    .instance
                    .addPostFrameCallback(
                      (_) =>
                      _scrollToBottom(),
                );

                return ChatMessageList(
                  messages: messages,
                  currentUserId:
                  _myUserId,
                  scrollController:
                  _scrollController,
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
            _sendVoiceMessage,

            onTyping: (text) {
              // Typing indicator logic
            },
          ),
        ],
      ),
    );
  }
}