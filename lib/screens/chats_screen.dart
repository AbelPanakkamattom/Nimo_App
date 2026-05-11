import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/profile_avatarz.dart';
import 'archived_chats_screen.dart';
import 'auth_screen.dart';
import 'chat_detail_screen.dart';
import 'contacts_screen.dart';
import 'contact_profile_screen.dart';
import 'settings_screen.dart';
import 'starred_messages_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  static const Color primary = Color(0xFF6C5CE7);

  final SupabaseClient client = Supabase.instance.client;

  final TextEditingController searchController =
  TextEditingController();

  String search = '';

  final Set<String> mutedChats = {};
  final Set<String> archivedChats = {};

  String get myId =>
      client.auth.currentUser?.id ?? '';

  // =========================================================
  // GET CHATS
  // =========================================================

  Stream<List<Map<String, dynamic>>> getChats() {
    if (myId.isEmpty) {
      return Stream.value([]);
    }

    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final filtered = rows.where((msg) {
        return msg['sender_id'] == myId ||
            msg['receiver_id'] == myId;
      }).toList();

      filtered.sort((a, b) {
        final bDate = DateTime.tryParse(
          b['created_at'].toString(),
        ) ??
            DateTime(2000);

        final aDate = DateTime.tryParse(
          a['created_at'].toString(),
        ) ??
            DateTime(2000);

        return bDate.compareTo(aDate);
      });

      final Map<String, Map<String, dynamic>>
      latestByUser = {};

      for (final msg in filtered) {
        final otherId = msg['sender_id'] == myId
            ? msg['receiver_id'].toString()
            : msg['sender_id'].toString();

        if (!latestByUser.containsKey(otherId)) {
          latestByUser[otherId] = msg;
        }
      }

      return latestByUser.values.toList();
    });
  }

  // =========================================================
  // GET USER
  // =========================================================

  Future<Map<String, dynamic>> getUser(
      String otherId,
      ) async {
    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', otherId)
          .maybeSingle();

      final contact = await client
          .from('contacts')
          .select()
          .eq('user_id', myId)
          .eq('contact_user_id', otherId)
          .maybeSingle();

      return {
        'name':
        contact?['custom_name'] ??
            profile?['name'] ??
            'User',
        'avatar':
        profile?['avatar_url'] ?? '',
        'online':
        profile?['is_online'] == true,
      };
    } catch (_) {
      return {
        'name': 'User',
        'avatar': '',
        'online': false,
      };
    }
  }

  // =========================================================
  // UNREAD COUNT
  // =========================================================

  Future<int> getUnreadCount(
      String otherId,
      ) async {
    try {
      final rows = await client
          .from('messages')
          .select()
          .eq('sender_id', otherId)
          .eq('receiver_id', myId)
          .neq('status', 'seen');

      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String formatTime(dynamic value) {
    try {
      final date = DateTime.parse(
        value.toString(),
      ).toLocal();

      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        int hour = date.hour;

        final minute = date.minute
            .toString()
            .padLeft(2, '0');

        final period =
        hour >= 12 ? 'PM' : 'AM';

        if (hour > 12) hour -= 12;

        if (hour == 0) hour = 12;

        return '$hour:$minute $period';
      }

      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  // =========================================================
  // MESSAGE PREVIEW
  // =========================================================

  String formatPreview(
      Map<String, dynamic> message,
      ) {
    final type =
        message['type']?.toString() ?? 'text';

    final content =
        message['content']
            ?.toString()
            .trim() ??
            '';

    switch (type) {
      case 'image':
        return '📷 Photo';

      case 'video':
        return '🎥 Video';

      case 'audio':
        return '🎤 Voice Message';

      case 'file':
        return '📎 File';

      default:
        return content.isEmpty
            ? 'Message'
            : content;
    }
  }

  // =========================================================
  // DELETE CHAT
  // =========================================================

  Future<void> deleteChat(
      String otherId,
      ) async {
    try {
      await client
          .from('messages')
          .delete()
          .or(
        'and(sender_id.eq.$myId,receiver_id.eq.$otherId),'
            'and(sender_id.eq.$otherId,receiver_id.eq.$myId)',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Chat deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
          (route) => false,
    );
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  Widget buildStatus(String status) {
    switch (status) {
      case 'seen':
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Color(0xFFFFD700),
        );

      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.grey.withValues(
            alpha: 0.80,
          ),
        );

      default:
        return Icon(
          Icons.check,
          size: 16,
          color: Colors.grey.withValues(
            alpha: 0.80,
          ),
        );
    }
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget buildEmptyState() {
    return const Center(
      child: Text(
        'No chats yet',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  // =========================================================
  // CHAT TILE
  // =========================================================

  Widget buildChatTile({
    required String otherId,
    required String name,
    required String avatar,
    required bool online,
    required String preview,
    required String time,
    required bool isMe,
    required String status,
    required int unread,
  }) {
    final muted =
    mutedChats.contains(otherId);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatDetailScreen(
                    otherUserId: otherId,
                    otherUserName: name,
                    otherUserAvatar: avatar,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProfileAvatar(
                name: name,
                imageUrl: avatar,
                radius: 30,
                isOnline: online,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),

                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey
                                .withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        if (isMe)
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              right: 5,
                            ),
                            child:
                            buildStatus(
                              status,
                            ),
                          ),

                        Expanded(
                          child: Text(
                            muted
                                ? 'Muted'
                                : preview,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style: TextStyle(
                              color:
                              Colors.grey
                                  .withValues(
                                alpha: 0.90,
                              ),
                            ),
                          ),
                        ),

                        if (unread > 0)
                          Container(
                            padding:
                            const EdgeInsets.all(
                              6,
                            ),
                            decoration:
                            const BoxDecoration(
                              color: primary,
                              shape:
                              BoxShape.circle,
                            ),
                            child: Text(
                              unread.toString(),
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontSize: 10,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ContactProfileScreen(
                                userId: otherId,
                              ),
                        ),
                      );
                      break;

                    case 'mute':
                      setState(() {
                        if (muted) {
                          mutedChats.remove(
                            otherId,
                          );
                        } else {
                          mutedChats.add(
                            otherId,
                          );
                        }
                      });
                      break;

                    case 'archive':
                      setState(() {
                        archivedChats.add(
                          otherId,
                        );
                      });
                      break;

                    case 'delete':
                      await deleteChat(
                        otherId,
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child:
                    Text('View Contact'),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(
                      muted
                          ? 'Unmute'
                          : 'Mute',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child:
                    Text('Delete Chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor: primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ContactsScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // HEADER
            // =================================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'archived':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const ArchivedChatsScreen(),
                            ),
                          );
                          break;

                        case 'starred':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const StarredMessagesScreen(),
                            ),
                          );
                          break;

                        case 'settings':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const SettingsScreen(),
                            ),
                          );
                          break;

                        case 'logout':
                          logout();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'archived',
                        child: Text(
                          'Archived Chats',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'starred',
                        child: Text(
                          'Starred Messages',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child:
                        Text('Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =================================================
            // SEARCH
            // =================================================

            Padding(
              padding:
              const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: TextField(
                  controller:
                  searchController,
                  onChanged: (value) {
                    setState(() {
                      search =
                          value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                    'Search chats...',
                    hintStyle: TextStyle(
                      color:
                      Colors.grey
                          .withValues(
                        alpha: 0.60,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                    border:
                    InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ),

            // =================================================
            // CHAT LIST
            // =================================================

            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream: getChats(),
                builder:
                    (context, snapshot) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  final chats =
                      snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return buildEmptyState();
                  }

                  return ListView.builder(
                    padding:
                    const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 100,
                    ),
                    itemCount:
                    chats.length,
                    itemBuilder:
                        (context, index) {
                      final message =
                      chats[index];

                      final otherId =
                      message['sender_id'] ==
                          myId
                          ? message[
                      'receiver_id']
                          .toString()
                          : message[
                      'sender_id']
                          .toString();

                      if (archivedChats
                          .contains(
                          otherId)) {
                        return const SizedBox
                            .shrink();
                      }

                      return FutureBuilder<
                          List<dynamic>>(
                        future:
                        Future.wait(
                          [
                            getUser(
                              otherId,
                            ),
                            getUnreadCount(
                              otherId,
                            ),
                          ],
                        ),
                        builder: (
                            context,
                            snapshot,
                            ) {
                          if (!snapshot
                              .hasData) {
                            return const SizedBox
                                .shrink();
                          }

                          final data =
                          snapshot
                              .data!;

                          final user =
                          data[0]
                          as Map<
                              String,
                              dynamic>;

                          final unread =
                          data[1]
                          as int;

                          final name =
                          user['name']
                              .toString();

                          if (search
                              .isNotEmpty &&
                              !name
                                  .toLowerCase()
                                  .contains(
                                search
                                    .toLowerCase(),
                              )) {
                            return const SizedBox
                                .shrink();
                          }

                          return buildChatTile(
                            otherId:
                            otherId,
                            name: name,
                            avatar: user[
                            'avatar']
                                .toString(),
                            online:
                            user['online'] ==
                                true,
                            preview:
                            formatPreview(
                              message,
                            ),
                            time:
                            formatTime(
                              message[
                              'created_at'],
                            ),
                            isMe:
                            message[
                            'sender_id'] ==
                                myId,
                            status:
                            message[
                            'status']
                                ?.toString() ??
                                'sent',
                            unread:
                            unread,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}