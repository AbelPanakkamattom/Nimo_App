import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'archived_chats_screen.dart';
import 'auth_screen.dart';
import 'chat_detail_screen.dart';
import 'contact_profile_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import 'starred_messages_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() =>
      _ChatsScreenState();
}

class _ChatsScreenState
    extends State<ChatsScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  final TextEditingController
  searchController =
  TextEditingController();

  String search = '';

  final Set<String> mutedChats = {};

  final Set<String> archivedChats = {};

  String get myId =>
      client.auth.currentUser?.id ?? '';

  /// =========================
  /// GET CHATS
  /// =========================

  Stream<List<Map<String, dynamic>>>
  getChats() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final filtered =
      rows.where((msg) {
        return msg['sender_id'] ==
            myId ||
            msg['receiver_id'] ==
                myId;
      }).toList();

      filtered.sort((a, b) {
        return DateTime.parse(
          b['created_at'],
        ).compareTo(
          DateTime.parse(
            a['created_at'],
          ),
        );
      });

      final Map<String,
          Map<String, dynamic>>
      unique = {};

      for (final msg in filtered) {
        final otherId =
        msg['sender_id'] == myId
            ? msg['receiver_id']
            : msg['sender_id'];

        if (!unique
            .containsKey(otherId)) {
          unique[otherId] = msg;
        }
      }

      return unique.values.toList();
    });
  }

  /// =========================
  /// GET USER
  /// =========================

  Future<Map<String, dynamic>>
  getUser(String otherId) async {
    try {
      final profile =
      await client
          .from('profiles')
          .select()
          .eq('id', otherId)
          .maybeSingle();

      final contact =
      await client
          .from('contacts')
          .select()
          .eq('user_id', myId)
          .eq(
        'contact_user_id',
        otherId,
      )
          .maybeSingle();

      return {
        'name':
        contact?['custom_name'] ??
            profile?['name'] ??
            'User',
        'avatar':
        profile?['avatar_url'] ??
            '',
        'online':
        profile?['is_online'] ??
            false,
      };
    } catch (_) {
      return {
        'name': 'User',
        'avatar': '',
        'online': false,
      };
    }
  }

  /// =========================
  /// TIME FORMAT
  /// =========================

  String formatTime(dynamic value) {
    try {
      final date =
      DateTime.parse(
        value.toString(),
      ).toLocal();

      int hour = date.hour;

      final minute = date.minute
          .toString()
          .padLeft(2, '0');

      final period =
      hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) {
        hour -= 12;
      }

      if (hour == 0) {
        hour = 12;
      }

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  /// =========================
  /// UNREAD COUNT
  /// =========================

  Future<int> getUnread(
      String otherId,
      ) async {
    try {
      final data = await client
          .from('messages')
          .select()
          .eq('sender_id', otherId)
          .eq('receiver_id', myId)
          .neq('status', 'seen');

      return data.length;
    } catch (_) {
      return 0;
    }
  }

  /// =========================
  /// DELETE CHAT
  /// =========================

  Future<void> deleteChat(
      String otherId) async {
    try {
      await client
          .from('messages')
          .delete()
          .or(
        'and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Chat deleted',
          ),
        ),
      );
    } catch (_) {}
  }

  /// =========================
  /// LOGOUT
  /// =========================

  Future<void> logout() async {
    final navigator =
    Navigator.of(context);

    await client.auth.signOut();

    if (!mounted) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const AuthScreen(),
      ),
          (route) => false,
    );
  }

  /// =========================
  /// STATUS ICON
  /// =========================

  Widget buildStatus(String status) {
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
        color: Colors.blue,
      );
    }

    return const Icon(
      Icons.check,
      size: 16,
      color: Colors.grey,
    );
  }

  /// =========================
  /// CHAT TILE
  /// =========================

  Widget buildTile({
    required String otherId,
    required String name,
    required String avatar,
    required bool online,
    required String message,
    required String time,
    required bool isMe,
    required String status,
    required int unread,
  }) {
    final muted =
    mutedChats.contains(otherId);

    return InkWell(
      borderRadius:
      BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(
                  receiverId: otherId,
                  name: name,
                  avatarUrl: avatar,
                ),
          ),
        );
      },
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
        const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            24,
          ),
        ),
        child: Row(
          children: [
            /// AVATAR
            Stack(
              children: [
                avatar.isNotEmpty
                    ? CircleAvatar(
                  radius: 30,
                  backgroundImage:
                  NetworkImage(
                    avatar,
                  ),
                )
                    : CircleAvatar(
                  radius: 30,
                  backgroundColor:
                  const Color(
                    0xFF6C5CE7,
                  ),
                  child: Text(
                    name[0]
                        .toUpperCase(),
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                    ),
                  ),
                ),

                if (online)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.green,
                        shape:
                        BoxShape.circle,
                        border:
                        Border.all(
                          color:
                          Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            /// CHAT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
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
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      Text(
                        time,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize: 12,
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
                          const EdgeInsets
                              .only(
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
                              : message,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ),

                      if (unread > 0)
                        Container(
                          padding:
                          const EdgeInsets
                              .all(7),
                          decoration:
                          const BoxDecoration(
                            color: Color(
                              0xFF6C5CE7,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                          child: Text(
                            unread
                                .toString(),
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            /// MENU
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ContactProfileScreen(
                            userId:
                            otherId,
                          ),
                    ),
                  );
                }

                if (value == 'mute') {
                  setState(() {
                    if (mutedChats
                        .contains(
                        otherId)) {
                      mutedChats.remove(
                          otherId);
                    } else {
                      mutedChats.add(
                          otherId);
                    }
                  });

                  ScaffoldMessenger.of(
                      context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        mutedChats.contains(
                            otherId)
                            ? 'Chat muted'
                            : 'Chat unmuted',
                      ),
                    ),
                  );
                }

                if (value ==
                    'archive') {
                  setState(() {
                    archivedChats
                        .add(otherId);
                  });

                  ScaffoldMessenger.of(
                      context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chat archived',
                      ),
                    ),
                  );
                }

                if (value == 'delete') {
                  deleteChat(otherId);
                }
              },
              itemBuilder: (_) => [
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
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        const Color(0xFF6C5CE7),
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
          Icons.chat,
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
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
                      if (value ==
                          'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const SettingsScreen(),
                          ),
                        );
                      }

                      if (value ==
                          'archived') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ArchivedChatsScreen(),
                          ),
                        );
                      }

                      if (value ==
                          'starred') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const StarredMessagesScreen(),
                          ),
                        );
                      }

                      if (value ==
                          'logout') {
                        logout();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'group',
                        child:
                        Text('New Group'),
                      ),
                      const PopupMenuItem(
                        value:
                        'archived',
                        child: Text(
                          'Archived Chats',
                        ),
                      ),
                      const PopupMenuItem(
                        value:
                        'starred',
                        child: Text(
                          'Starred Messages',
                        ),
                      ),
                      const PopupMenuItem(
                        value:
                        'settings',
                        child:
                        Text('Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child:
                        Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding:
              const EdgeInsets.all(
                20,
              ),
              child: Container(
                decoration:
                BoxDecoration(
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
                      search = value;
                    });
                  },
                  decoration:
                  const InputDecoration(
                    hintText:
                    'Search chats...',
                    prefixIcon: Icon(
                      Icons.search,
                    ),
                    border:
                    InputBorder.none,
                  ),
                ),
              ),
            ),

            /// CHAT LIST
            Expanded(
              child: StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream: getChats(),
                builder:
                    (context, snapshot) {
                  if (!snapshot
                      .hasData) {
                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  final chats =
                      snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return const Center(
                      child: Text(
                        'No chats yet',
                      ),
                    );
                  }

                  return ListView
                      .builder(
                    padding:
                    const EdgeInsets
                        .only(
                      left: 20,
                      right: 20,
                      bottom: 120,
                    ),
                    itemCount:
                    chats.length,
                    itemBuilder:
                        (context, index) {
                      final msg =
                      chats[index];

                      final otherId =
                      msg['sender_id'] ==
                          myId
                          ? msg[
                      'receiver_id']
                          : msg[
                      'sender_id'];

                      if (archivedChats
                          .contains(
                          otherId)) {
                        return const SizedBox();
                      }

                      return FutureBuilder(
                        future:
                        Future.wait(
                          [
                            getUser(otherId),
                            getUnread(
                                otherId),
                          ],
                        ),
                        builder:
                            (context,
                            snap) {
                          if (!snap
                              .hasData) {
                            return const SizedBox();
                          }

                          final data =
                          snap.data!;

                          final user =
                          data[0]
                          as Map<
                              String,
                              dynamic>;

                          final unread =
                          data[1]
                          as int;

                          final name =
                          user['name'];

                          if (search
                              .isNotEmpty &&
                              !name
                                  .toLowerCase()
                                  .contains(
                                search
                                    .toLowerCase(),
                              )) {
                            return const SizedBox();
                          }

                          return buildTile(
                            otherId:
                            otherId,
                            name: name,
                            avatar:
                            user['avatar'],
                            online:
                            user['online'],
                            message:
                            msg['content'] ??
                                '',
                            time:
                            formatTime(
                              msg[
                              'created_at'],
                            ),
                            isMe:
                            msg['sender_id'] ==
                                myId,
                            status:
                            msg['status'] ??
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