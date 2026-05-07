import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState
    extends State<BlockedUsersScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  List<Map<String, dynamic>>
  blockedUsers = [];

  bool loading = true;

  String get myId =>
      client.auth.currentUser!.id;

  /// =====================================
  /// 🚫 LOAD BLOCKED USERS
  /// =====================================

  Future<void> loadBlockedUsers() async {
    try {
      setState(() {
        loading = true;
      });

      final blockedResponse =
      await client
          .from('blocked_users')
          .select()
          .eq(
        'blocker_id',
        myId,
      );

      final List<
          Map<String, dynamic>>
      loadedUsers = [];

      for (final item
      in blockedResponse) {
        final blockedId =
        item['blocked_id'];

        final profile =
        await client
            .from('profiles')
            .select()
            .eq(
          'id',
          blockedId,
        )
            .maybeSingle();

        if (profile != null) {
          loadedUsers.add({
            ...profile,
            'blocked_id':
            blockedId,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        blockedUsers =
            loadedUsers;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to load blocked users",
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /// =====================================
  /// 🔓 UNBLOCK USER
  /// =====================================

  Future<void> unblockUser(
      String blockedId,
      ) async {
    try {
      await client
          .from('blocked_users')
          .delete()
          .match({
        'blocker_id': myId,
        'blocked_id':
        blockedId,
      });

      blockedUsers.removeWhere(
            (user) =>
        user['id'] ==
            blockedId,
      );

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "User unblocked",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to unblock user",
          ),
        ),
      );
    }
  }

  /// =====================================
  /// 🚀 INIT
  /// =====================================

  @override
  void initState() {
    super.initState();
    loadBlockedUsers();
  }

  /// =====================================
  /// 👤 USER TILE
  /// =====================================

  Widget buildUserTile(
      Map<String, dynamic> user,
      ) {
    final avatar =
    user['avatar_url']
        ?.toString();

    final name =
        user['name']
            ?.toString() ??
            'User';

    final email =
        user['email']
            ?.toString() ??
            '';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          /// 👤 AVATAR
          avatar != null &&
              avatar.isNotEmpty
              ? CircleAvatar(
            radius: 28,
            backgroundImage:
            NetworkImage(
              avatar,
            ),
          )
              : CircleAvatar(
            radius: 28,
            backgroundColor:
            const Color(
              0xFF6C5CE7,
            ),
            child: Text(
              name
                  .substring(
                0,
                1,
              )
                  .toUpperCase(),
              style:
              const TextStyle(
                color:
                Colors.white,
                fontSize: 20,
                fontWeight:
                FontWeight
                    .bold,
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          /// 👤 INFO
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  name,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  email,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          /// 🔓 BUTTON
          ElevatedButton(
            onPressed: () =>
                unblockUser(
                  user['id'],
                ),
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              Colors.red,
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
            ),
            child: const Text(
              "Unblock",
            ),
          ),
        ],
      ),
    );
  }

  /// =====================================
  /// 🎨 UI
  /// =====================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F6FF,
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.transparent,
        title: const Text(
          "Blocked Users",
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body:
      loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : blockedUsers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors
                  .grey
                  .shade400,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              "No blocked users",
              style: TextStyle(
                fontSize: 18,
                color: Colors
                    .grey
                    .shade700,
                fontWeight:
                FontWeight
                    .w500,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh:
        loadBlockedUsers,
        child: ListView(
          padding:
          const EdgeInsets.all(
            18,
          ),
          children:
          blockedUsers
              .map(
                (
                user,
                ) =>
                buildUserTile(
                  user,
                ),
          )
              .toList(),
        ),
      ),
    );
  }
}