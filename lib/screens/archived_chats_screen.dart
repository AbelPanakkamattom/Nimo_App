import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/profile_avatarz.dart';
import 'chat_detail_screen.dart';

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() =>
      _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState
    extends State<ArchivedChatsScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  static const Color primary =
  Color(0xFF6C5CE7);

  String get myId =>
      supabase.auth.currentUser?.id ?? '';

  // ==========================================
  // LOAD ARCHIVED CHATS
  // ==========================================

  Future<List<Map<String, dynamic>>>
  loadArchivedChats() async {
    if (myId.isEmpty) {
      return [];
    }

    try {
      final contacts =
      await supabase
          .from('contacts')
          .select()
          .eq('user_id', myId)
          .eq('archived', true)
          .order(
        'created_at',
        ascending: false,
      );

      return List<Map<String,
          dynamic>>.from(
        contacts,
      );
    } catch (e) {
      debugPrint(
        'LOAD ARCHIVED CHATS ERROR: $e',
      );
      return [];
    }
  }

  // ==========================================
  // GET USER PROFILE
  // ==========================================

  Future<Map<String, dynamic>?>
  getProfile(
      String userId,
      ) async {
    if (userId.trim().isEmpty) {
      return null;
    }

    try {
      final profile =
      await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        return null;
      }

      return Map<String,
          dynamic>.from(
        profile,
      );
    } catch (e) {
      debugPrint(
        'PROFILE ERROR: $e',
      );
      return null;
    }
  }

  // ==========================================
  // UNARCHIVE CHAT
  // ==========================================

  Future<void> unarchiveChat(
      String contactUserId,
      ) async {
    try {
      await supabase
          .from('contacts')
          .update({
        'archived': false,
      })
          .eq(
        'user_id',
        myId,
      )
          .eq(
        'contact_user_id',
        contactUserId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Chat unarchived.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to unarchive chat.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    }
  }

  // ==========================================
  // OPEN CHAT
  // ==========================================

  void openChat({
    required String otherUserId,
    required String name,
    required String avatarUrl,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(
              otherUserId:
              otherUserId,
              otherUserName:
              name,
              otherUserAvatar:
              avatarUrl,
            ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration:
              BoxDecoration(
                color: primary
                    .withAlpha(
                  20,
                ),
                shape:
                BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .archive_outlined,
                size: 50,
                color: primary,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            const Text(
              'No Archived Chats',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Chats that you archive will appear here.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors
                    .grey
                    .shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (myId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not logged in.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F6FF,
      ),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          'Archived Chats',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<
          List<Map<String,
              dynamic>>>(
        future: loadArchivedChats(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot
              .connectionState ==
              ConnectionState
                  .waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color: primary,
              ),
            );
          }

          final chats =
              snapshot.data ??
                  [];

          if (chats.isEmpty) {
            return buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: primary,
            child:
            ListView.builder(
              padding:
              const EdgeInsets.all(
                16,
              ),
              itemCount:
              chats.length,
              itemBuilder: (
                  context,
                  index,
                  ) {
                final chat =
                chats[index];

                final otherUserId =
                (chat['contact_user_id'] ??
                    '')
                    .toString();

                if (otherUserId
                    .isEmpty) {
                  return const SizedBox
                      .shrink();
                }

                return FutureBuilder<
                    Map<String,
                        dynamic>?>(
                  future:
                  getProfile(
                    otherUserId,
                  ),
                  builder: (
                      context,
                      profileSnapshot,
                      ) {
                    if (!profileSnapshot
                        .hasData ||
                        profileSnapshot
                            .data ==
                            null) {
                      return const SizedBox
                          .shrink();
                    }

                    final profile =
                    profileSnapshot
                        .data!;

                    final name =
                    (profile['name'] ??
                        'User')
                        .toString();

                    final avatarUrl =
                    (profile[
                    'avatar_url'] ??
                        '')
                        .toString();

                    final isOnline =
                        profile[
                        'is_online'] ==
                            true;

                    return Container(
                      margin:
                      const EdgeInsets.only(
                        bottom:
                        14,
                      ),
                      decoration:
                      BoxDecoration(
                        color: Colors
                            .white,
                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withAlpha(
                              8,
                            ),
                            blurRadius:
                            10,
                            offset:
                            const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),
                      child:
                      ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          14,
                          vertical:
                          8,
                        ),
                        onTap: () =>
                            openChat(
                              otherUserId:
                              otherUserId,
                              name:
                              name,
                              avatarUrl:
                              avatarUrl,
                            ),
                        leading:
                        ProfileAvatar(
                          name:
                          name,
                          imageUrl:
                          avatarUrl
                              .isEmpty
                              ? null
                              : avatarUrl,
                          radius:
                          28,
                          isOnline:
                          isOnline,
                        ),
                        title:
                        Text(
                          name,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        subtitle:
                        const Text(
                          'Archived chat',
                        ),
                        trailing:
                        PopupMenuButton<
                            String>(
                          onSelected:
                              (
                              value,
                              ) {
                            if (value ==
                                'unarchive') {
                              unarchiveChat(
                                otherUserId,
                              );
                            }
                          },
                          itemBuilder:
                              (
                              context,
                              ) =>
                          const [
                            PopupMenuItem(
                              value:
                              'unarchive',
                              child:
                              Text(
                                'Unarchive',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}