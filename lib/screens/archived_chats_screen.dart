import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_detail_screen.dart';

class ArchivedChatsScreen
    extends StatefulWidget {
  const ArchivedChatsScreen({
    super.key,
  });

  @override
  State<ArchivedChatsScreen>
  createState() =>
      _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState
    extends State<ArchivedChatsScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "User not logged in",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        title: const Text(
          'Archived Chats',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          List<Map<String, dynamic>>>(
        stream: supabase
            .from('contacts')
            .stream(
          primaryKey: ['id'],
        ),

        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return _emptyState();
          }

          final allChats =
          snapshot.data!;

          final archivedChats =
          allChats.where(
                (chat) {
              return chat['user_id'] ==
                  user.id &&
                  chat['archived'] ==
                      true;
            },
          ).toList();

          if (archivedChats.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),

            itemCount:
            archivedChats.length,

            itemBuilder:
                (context, index) {
              final chat =
              archivedChats[index];

              final contactUserId =
              chat[
              'contact_user_id'];

              return FutureBuilder<
                  Map<String,
                      dynamic>?>(
                future: _getProfile(
                  contactUserId,
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
                    return const SizedBox();
                  }

                  final profile =
                  profileSnapshot
                      .data!;

                  final name =
                      profile['name'] ??
                          'User';

                  final avatar =
                      profile[
                      'avatar_url'] ??
                          '';

                  return Container(
                    margin:
                    const EdgeInsets.only(
                      bottom: 14,
                    ),

                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                        22,
                      ),
                    ),

                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.all(
                        14,
                      ),

                      leading:
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        const Color(
                          0xFF6C5CE7,
                        ),

                        backgroundImage:
                        avatar
                            .toString()
                            .isNotEmpty
                            ? NetworkImage(
                          avatar,
                        )
                            : null,

                        child: avatar
                            .toString()
                            .isEmpty
                            ? Text(
                          name[0]
                              .toUpperCase(),

                          style:
                          const TextStyle(
                            color: Colors
                                .white,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        )
                            : null,
                      ),

                      title: Text(
                        name,

                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      subtitle: const Text(
                        "Archived chat",
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatDetailScreen(
                                  receiverId:
                                  contactUserId,

                                  name: name,
                                ),
                          ),
                        );
                      },

                      trailing:
                      PopupMenuButton(
                        onSelected:
                            (value) async {
                          if (value ==
                              'unarchive') {
                            await supabase
                                .from(
                                'contacts')
                                .update({
                              'archived':
                              false,
                            })
                                .eq(
                              'user_id',
                              user.id,
                            )
                                .eq(
                              'contact_user_id',
                              contactUserId,
                            );

                            if (!context
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Chat unarchived",
                                ),
                              ),
                            );
                          }
                        },

                        itemBuilder:
                            (context) => [
                          const PopupMenuItem(
                            value:
                            'unarchive',

                            child: Text(
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
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Container(
              width: 100,
              height: 100,

              decoration:
              BoxDecoration(
                color: const Color(
                  0xFF6C5CE7,
                ).withAlpha(20),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.archive_outlined,
                size: 50,
                color: Color(
                  0xFF6C5CE7,
                ),
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
                color:
                Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?>
  _getProfile(
      String userId,
      ) async {
    try {
      final response =
      await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint(
        "PROFILE ERROR: $e",
      );

      return null;
    }
  }
}