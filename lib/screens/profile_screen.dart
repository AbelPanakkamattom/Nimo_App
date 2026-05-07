import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'blocked_users_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  static const Color primary =
  Color(0xFF6C5CE7);

  Map<String, dynamic>? profile;

  bool loading = true;

  int chatsCount = 0;
  int mediaCount = 0;
  int callsCount = 0;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  /// ======================================
  /// LOAD PROFILE
  /// ======================================

  Future<void> loadProfile() async {
    final user =
        client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    try {
      final profileData =
      await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final messages =
      await client
          .from('messages')
          .select();

      int chats = 0;
      int media = 0;

      final uniqueChats =
      <String>{};

      for (final msg in messages) {
        final sender =
        msg['sender_id'];
        final receiver =
        msg['receiver_id'];

        if (sender == user.id ||
            receiver == user.id) {
          final other =
          sender == user.id
              ? receiver
              : sender;

          uniqueChats.add(
            other.toString(),
          );

          final type =
              msg['type']
                  ?.toString() ??
                  'text';

          if (type == 'image' ||
              type == 'audio') {
            media++;
          }
        }
      }

      chats = uniqueChats.length;

      if (!mounted) return;

      setState(() {
        profile = profileData;
        chatsCount = chats;
        mediaCount = media;
        callsCount = 0;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load profile',
          ),
        ),
      );
    }
  }

  /// ======================================
  /// LOGOUT
  /// ======================================

  Future<void> logout() async {
    final navigator =
    Navigator.of(context);

    await client.auth.signOut();

    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const AuthScreen(),
      ),
          (route) => false,
    );
  }

  /// ======================================
  /// DELETE ACCOUNT
  /// ======================================

  Future<void> deleteAccount() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
          ),
          content: const Text(
            'This action is permanent.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final user =
          client.auth.currentUser;

      if (user == null) return;

      await client
          .from('profiles')
          .delete()
          .eq('id', user.id);

      await client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const AuthScreen(),
        ),
            (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete account',
          ),
        ),
      );
    }
  }

  /// ======================================
  /// OPEN EDIT
  /// ======================================

  Future<void>
  openEditProfile() async {
    if (profile == null) return;

    final result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(
              profile: profile!,
            ),
      ),
    );

    if (result == true) {
      await loadProfile();
    }
  }

  /// ======================================
  /// BLOCKED USERS
  /// ======================================

  void openBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const BlockedUsersScreen(),
      ),
    );
  }

  /// ======================================
  /// AVATAR
  /// ======================================

  Widget buildAvatar() {
    final avatar =
        profile?['avatar_url']
            ?.toString() ??
            '';

    if (avatar.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundImage:
        NetworkImage(avatar),
      );
    }

    final name =
        profile?['name']
            ?.toString() ??
            'U';

    return CircleAvatar(
      radius: 58,
      backgroundColor: primary,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  /// ======================================
  /// UI
  /// ======================================

  @override
  Widget build(BuildContext context) {
    final username =
        profile?['name'] ??
            profile?['username'] ??
            'User';

    final email =
        profile?['email'] ?? '';

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: loadProfile,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// HEADER
              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.only(
                  top: 65,
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                decoration:
                const BoxDecoration(
                  gradient:
                  LinearGradient(
                    colors: [
                      primary,
                      Color(
                        0xFF8E7BFF,
                      ),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.only(
                    bottomLeft:
                    Radius.circular(
                        34),
                    bottomRight:
                    Radius.circular(
                        34),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style:
                          TextStyle(
                            color: Colors
                                .white,
                            fontSize:
                            28,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                        IconButton(
                          onPressed:
                          logout,
                          icon:
                          const Icon(
                            Icons.logout,
                            color: Colors
                                .white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    buildAvatar(),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      username,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 28,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      email,
                      style: TextStyle(
                        color: Colors
                            .white
                            .withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width: 190,
                      height: 48,
                      child:
                      ElevatedButton
                          .icon(
                        onPressed:
                        openEditProfile,
                        icon:
                        const Icon(
                          Icons.edit,
                          size: 18,
                        ),
                        label:
                        const Text(
                          'Edit Profile',
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors
                              .white,
                          foregroundColor:
                          primary,
                          elevation:
                          0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 24),

              /// STATS
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: statCard(
                        'Chats',
                        chatsCount
                            .toString(),
                        Icons.chat,
                      ),
                    ),
                    const SizedBox(
                        width: 12),
                    Expanded(
                      child: statCard(
                        'Calls',
                        callsCount
                            .toString(),
                        Icons.call,
                      ),
                    ),
                    const SizedBox(
                        width: 12),
                    Expanded(
                      child: statCard(
                        'Media',
                        mediaCount
                            .toString(),
                        Icons.image,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 24),

              /// SETTINGS
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    settingTile(
                      icon:
                      Icons.lock,
                      title:
                      'Privacy',
                      subtitle:
                      'Manage your privacy',
                      onTap: () {
                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Coming soon',
                            ),
                          ),
                        );
                      },
                    ),

                    settingTile(
                      icon:
                      Icons.block,
                      title:
                      'Blocked Users',
                      subtitle:
                      'View blocked people',
                      onTap:
                      openBlockedUsers,
                    ),

                    settingTile(
                      icon:
                      Icons.help,
                      title:
                      'Help & Support',
                      subtitle:
                      'Report issues',
                      onTap: () {
                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Coming soon',
                            ),
                          ),
                        );
                      },
                    ),

                    settingTile(
                      icon:
                      Icons.delete,
                      title:
                      'Delete Account',
                      subtitle:
                      'Permanent delete',
                      color: Colors.red,
                      onTap:
                      deleteAccount,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 30),

              /// LOGOUT BUTTON
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: SizedBox(
                  width:
                  double.infinity,
                  height: 56,
                  child:
                  ElevatedButton
                      .icon(
                    onPressed: logout,
                    icon: const Icon(
                      Icons.logout,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// ======================================
  /// SETTINGS TILE
  /// ======================================

  Widget settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(20),
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
              20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.04,
              ),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
              BoxDecoration(
                color:
                color.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                BorderRadius.circular(
                    15),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(
                width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),

                  const SizedBox(
                      height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors
                          .grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// ======================================
  /// STAT CARD
  /// ======================================

  Widget statCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
          ),

          const SizedBox(
              height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}