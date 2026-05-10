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

  static const Color primary =
  Color(0xFF6C5CE7);

  List<Map<String, dynamic>> blockedUsers =
  [];

  bool loading = true;

  String? get myId =>
      client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadBlockedUsers();
  }

  // ==========================================
  // LOAD BLOCKED USERS
  // ==========================================

  Future<void> loadBlockedUsers() async {
    final userId = myId;

    if (userId == null) {
      if (mounted) {
        setState(() {
          blockedUsers = [];
          loading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final blockedResponse =
      await client
          .from('blocked_users')
          .select()
          .eq(
        'blocker_id',
        userId,
      );

      final List<Map<String, dynamic>>
      loadedUsers = [];

      for (final item
      in blockedResponse) {
        final blockedId =
        item['blocked_id']
            ?.toString();

        if (blockedId == null) {
          continue;
        }

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
        blockedUsers = loadedUsers;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load blocked users',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // UNBLOCK USER
  // ==========================================

  Future<void> unblockUser(
      String blockedId,
      ) async {
    final userId = myId;

    if (userId == null) return;

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
          ),
          title:
          const Text('Unblock User'),
          content: const Text(
            'Do you want to unblock this user?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Unblock',
                style: TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await client
          .from('blocked_users')
          .delete()
          .match({
        'blocker_id': userId,
        'blocked_id': blockedId,
      });

      if (!mounted) return;

      setState(() {
        blockedUsers.removeWhere(
              (user) =>
          user['id']
              .toString() ==
              blockedId,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('User unblocked'),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to unblock user',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget buildEmptyState() {
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
                color: Colors.red
                    .withAlpha(20),
                shape:
                BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            const Text(
              'No Blocked Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Users you block will appear here.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors
                    .grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // USER TILE
  // ==========================================

  Widget buildUserTile(
      Map<String, dynamic> user,
      ) {
    final avatarUrl =
        user['avatar_url']
            ?.toString() ??
            '';

    final name =
        user['name']
            ?.toString() ??
            user['username']
                ?.toString() ??
            'User';

    final email =
        user['email']
            ?.toString() ??
            '';

    final initial =
    name.trim().isNotEmpty
        ? name
        .trim()[0]
        .toUpperCase()
        : 'U';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withAlpha(8),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // AVATAR
          avatarUrl.isNotEmpty
              ? CircleAvatar(
            radius: 28,
            backgroundColor:
            Colors.grey
                .shade200,
            backgroundImage:
            NetworkImage(
              avatarUrl,
            ),
          )
              : CircleAvatar(
            radius: 28,
            backgroundColor:
            primary,
            child: Text(
              initial,
              style:
              const TextStyle(
                color: Colors
                    .white,
                fontSize: 20,
                fontWeight:
                FontWeight
                    .bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // INFO
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
                if (email.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      top: 4,
                    ),
                    child: Text(
                      email,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize:
                        13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // UNBLOCK BUTTON
          ElevatedButton(
            onPressed: () =>
                unblockUser(
                  user['id']
                      .toString(),
                ),
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              Colors.red,
              foregroundColor:
              Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
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
              'Unblock',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        surfaceTintColor:
        Colors.transparent,
        foregroundColor:
        Colors.black,
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(
          color: primary,
        ),
      )
          : blockedUsers.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
        color: primary,
        onRefresh:
        loadBlockedUsers,
        child: ListView.builder(
          padding:
          const EdgeInsets.all(
            18,
          ),
          itemCount:
          blockedUsers.length,
          itemBuilder:
              (context, index) {
            return buildUserTile(
              blockedUsers[
              index],
            );
          },
        ),
      ),
    );
  }
}