import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../services/supabase_chat_service.dart';
import '../services/supabase_storage_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String name;
  final String? avatarUrl;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.name,
    this.avatarUrl,
  });

  @override
  State<ChatDetailScreen> createState() =>
      _ChatDetailScreenState();
}

class _ChatDetailScreenState
    extends State<ChatDetailScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  final TextEditingController
  messageController =
  TextEditingController();

  final ScrollController
  scrollController =
  ScrollController();

  final AudioRecorder recorder =
  AudioRecorder();

  bool sending = false;
  bool recording = false;

  Timer? typingTimer;

  String get myId =>
      client.auth.currentUser!.id;

  /// =========================
  /// GET MESSAGES
  /// =========================

  Stream<List<Map<String, dynamic>>>
  getMessages() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final filtered =
      rows.where((msg) {
        return (msg['sender_id'] ==
            myId &&
            msg['receiver_id'] ==
                widget.receiverId) ||
            (msg['sender_id'] ==
                widget.receiverId &&
                msg['receiver_id'] ==
                    myId);
      }).toList();

      filtered.sort((a, b) {
        return DateTime.parse(
          a['created_at'],
        ).compareTo(
          DateTime.parse(
            b['created_at'],
          ),
        );
      });

      return filtered;
    });
  }

  /// =========================
  /// SEND MESSAGE
  /// =========================

  Future<void> sendMessage() async {
    final text =
    messageController.text.trim();

    if (text.isEmpty || sending) {
      return;
    }

    setState(() {
      sending = true;
    });

    final message = text;

    messageController.clear();

    try {
      await SupabaseChatService
          .sendMessage(
        receiverId: widget.receiverId,
        content: message,
        type: 'text',
      );

      await ProfileService.setTyping(
        receiverId: widget.receiverId,
        isTyping: false,
      );

      scrollBottom();
    } catch (e) {
      showSnack("Message failed");
    }

    if (!mounted) {
      return;
    }

    setState(() {
      sending = false;
    });
  }

  /// =========================
  /// SEND IMAGE
  /// =========================

  Future<void> sendImage() async {
    try {
      final picker = ImagePicker();

      final picked =
      await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) {
        return;
      }

      final file = File(picked.path);

      final url =
      await SupabaseStorageService
          .uploadImage(file);

      await SupabaseChatService
          .sendMessage(
        receiverId: widget.receiverId,
        content: url,
        type: 'image',
      );

      scrollBottom();
    } catch (e) {
      showSnack(
        "Image send failed",
      );
    }
  }

  /// =========================
  /// RECORD AUDIO
  /// =========================

  Future<void> toggleRecording() async {
    try {
      if (!recording) {
        final dir =
            Directory.systemTemp;

        final path =
            "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

        await recorder.start(
          const RecordConfig(),
          path: path,
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

      final file = File(path);

      final url =
      await SupabaseStorageService
          .uploadAudio(file);

      await SupabaseChatService
          .sendMessage(
        receiverId: widget.receiverId,
        content: url,
        type: 'audio',
      );

      scrollBottom();
    } catch (e) {
      showSnack(
        "Voice message failed",
      );
    }
  }

  /// =========================
  /// TYPING
  /// =========================

  Future<void> onTyping(
      String value,
      ) async {
    final typing =
        value.trim().isNotEmpty;

    await ProfileService.setTyping(
      receiverId: widget.receiverId,
      isTyping: typing,
    );

    typingTimer?.cancel();

    typingTimer = Timer(
      const Duration(seconds: 2),
          () async {
        await ProfileService.setTyping(
          receiverId:
          widget.receiverId,
          isTyping: false,
        );
      },
    );
  }

  /// =========================
  /// MARK SEEN
  /// =========================

  Future<void> markSeen() async {
    try {
      await SupabaseChatService
          .markAsSeen(
        widget.receiverId,
      );
    } catch (_) {}
  }

  /// =========================
  /// FORMAT TIME
  /// =========================

  String formatTime(dynamic value) {
    try {
      final date =
      DateTime.parse(value)
          .toLocal();

      int hour = date.hour;

      final minute = date.minute
          .toString()
          .padLeft(2, '0');

      final amPm =
      hour >= 12 ? "PM" : "AM";

      if (hour > 12) {
        hour -= 12;
      }

      if (hour == 0) {
        hour = 12;
      }

      return "$hour:$minute $amPm";
    } catch (_) {
      return "";
    }
  }

  /// =========================
  /// STATUS ICON
  /// =========================

  Widget buildStatus(
      String status,
      ) {
    if (status == 'seen') {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.amber,
      );
    }

    if (status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.white70,
      );
    }

    return const Icon(
      Icons.check,
      size: 16,
      color: Colors.white70,
    );
  }

  /// =========================
  /// AUTO SCROLL
  /// =========================

  void scrollBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController
          .hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController
            .position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  /// =========================
  /// SNACKBAR
  /// =========================

  void showSnack(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  /// =========================
  /// MESSAGE BUBBLE
  /// =========================

  Widget buildBubble(
      Map<String, dynamic> msg,
      ) {
    final isMe =
        msg['sender_id'] == myId;

    final type =
        msg['type'] ?? 'text';

    final content =
        msg['content'] ?? '';

    final status =
        msg['status'] ?? 'sent';

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        padding:
        const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(
            0xFF6C5CE7,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            if (type == 'image')
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                child: Image.network(
                  content,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              )
            else if (type == 'audio')
              Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic,
                    color: isMe
                        ? Colors.white
                        : Colors.black,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    "Voice Message",
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              )
            else
              Text(
                content,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : Colors.black,
                  fontSize: 15,
                ),
              ),

            const SizedBox(
              height: 6,
            ),

            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  formatTime(
                    msg['created_at'],
                  ),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white70
                        : Colors.grey,
                    fontSize: 10,
                  ),
                ),

                if (isMe) ...[
                  const SizedBox(
                    width: 5,
                  ),
                  buildStatus(status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// INIT
  /// =========================

  @override
  void initState() {
    super.initState();

    markSeen();
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        Map<String, dynamic>?>(
      stream:
      ProfileService.profileStream(
        widget.receiverId,
      ),
      builder:
          (context, profileSnap) {
        final profile =
            profileSnap.data;

        final online =
        ProfileService.isOnline(
          profile,
        );

        return StreamBuilder<bool>(
          stream:
          ProfileService.typingStream(
            widget.receiverId,
          ),
          builder:
              (context, typingSnap) {
            final typing =
                typingSnap.data ??
                    false;

            return Scaffold(
              backgroundColor:
              const Color(
                0xFFF5F6FF,
              ),
              body: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Container(
                      color: Colors.white,
                      padding:
                      const EdgeInsets
                          .all(12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                          ),

                          widget.avatarUrl !=
                              null &&
                              widget
                                  .avatarUrl!
                                  .isNotEmpty
                              ? CircleAvatar(
                            radius: 22,
                            backgroundImage:
                            NetworkImage(
                              widget
                                  .avatarUrl!,
                            ),
                          )
                              : CircleAvatar(
                            radius: 22,
                            backgroundColor:
                            const Color(
                              0xFF6C5CE7,
                            ),
                            child: Text(
                              widget
                                  .name[0]
                                  .toUpperCase(),
                              style:
                              const TextStyle(
                                color: Colors
                                    .white,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  widget.name,
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    fontSize:
                                    16,
                                  ),
                                ),

                                Text(
                                  typing
                                      ? "typing..."
                                      : online
                                      ? "online"
                                      : ProfileService
                                      .getLastSeenText(
                                    profile,
                                  ),
                                  style:
                                  TextStyle(
                                    color: typing
                                        ? Colors
                                        .green
                                        : Colors
                                        .grey,
                                    fontSize:
                                    12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton(
                            itemBuilder:
                                (_) => [
                              const PopupMenuItem(
                                value:
                                'view',
                                child: Text(
                                  "View Contact",
                                ),
                              ),
                              const PopupMenuItem(
                                value:
                                'block',
                                child: Text(
                                  "Block",
                                ),
                              ),
                            ],
                            onSelected:
                                (value) async {
                              if (value ==
                                  'block') {
                                await ProfileService
                                    .blockUser(
                                  widget
                                      .receiverId,
                                );

                                if (!mounted) {
                                  return;
                                }

                                showSnack(
                                  "User blocked",
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<
                        List<
                            Map<String,
                                dynamic>>>(
                      stream:
                      getMessages(),
                      builder: (
                          context,
                          snapshot,
                          ) {
                        final messages =
                            snapshot.data ??
                                [];

                        WidgetsBinding
                            .instance
                            .addPostFrameCallback(
                              (_) {
                            scrollBottom();
                          },
                        );

                        return ListView
                            .builder(
                          controller:
                          scrollController,
                          padding:
                          const EdgeInsets
                              .only(
                            top: 10,
                            bottom: 10,
                          ),
                          itemCount:
                          messages.length,
                          itemBuilder:
                              (_, i) {
                            return buildBubble(
                              messages[i],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  SafeArea(
                    top: false,
                    child: Container(
                      color: Colors.white,
                      padding:
                      const EdgeInsets
                          .all(10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                            sendImage,
                            icon:
                            const Icon(
                              Icons.image,
                            ),
                          ),

                          IconButton(
                            onPressed:
                            toggleRecording,
                            icon: Icon(
                              recording
                                  ? Icons.stop
                                  : Icons.mic,
                              color: recording
                                  ? Colors.red
                                  : null,
                            ),
                          ),

                          Expanded(
                            child: TextField(
                              controller:
                              messageController,
                              onChanged:
                              onTyping,
                              minLines: 1,
                              maxLines: 5,
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
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          GestureDetector(
                            onTap:
                            sendMessage,
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
                                  color: Colors
                                      .white,
                                  strokeWidth:
                                  2,
                                ),
                              )
                                  : const Icon(
                                Icons.send,
                                color: Colors
                                    .white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    typingTimer?.cancel();

    ProfileService.setTyping(
      receiverId: widget.receiverId,
      isTyping: false,
    );

    messageController.dispose();
    scrollController.dispose();
    recorder.dispose();

    super.dispose();
  }
}