import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
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
  static const Color primary =
  Color(0xFF6C5CE7);
  static const Color secondary =
  Color(0xFF8E7BFF);
  static const Color background =
  Color(0xFFF5F6FF);

  final SupabaseClient client =
      Supabase.instance.client;

  Map<String, dynamic>? profile;
  bool loading = true;

  int chatsCount = 0;
  int callsCount = 0;
  int mediaCount = 0;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

// =========================================================
// LOAD PROFILE
// =========================================================

  Future<void> loadProfile() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final user = client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
        return;
      }

      // Ensure profile exists
      await ProfileService.createProfileIfNotExists();

      // Load profile data
      final profileData =
      await ProfileService.getMyProfile();

      final safeProfile = profileData ??
          {
            'id': user.id,
            'email': user.email ?? '',
            'name': user.userMetadata?['name']
                ?.toString() ??
                user.email
                    ?.split('@')
                    .first ??
                'NIMO User',
            'bio': user.userMetadata?['bio']
                ?.toString() ??
                '',
            'description':
            user.userMetadata?['bio']
                ?.toString() ??
                '',
            'avatar_url':
            user.userMetadata?[
            'avatar_url']
                ?.toString() ??
                '',
          };

      // Load all statistics from ProfileService
      final stats =
      await ProfileService.getProfileStats();

      if (!mounted) return;

      setState(() {
        profile =
        Map<String, dynamic>.from(
          safeProfile,
        );

        chatsCount =
            stats['chats'] ?? 0;

        callsCount =
            stats['calls'] ?? 0;

        mediaCount =
            stats['media'] ?? 0;

        loading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD PROFILE ERROR: $e',
      );

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
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
        const AuthScreen(),
      ),
          (_) => false,
    );
  }

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Future<void> deleteAccount() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) =>
          AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                24,
              ),
            ),
            title: const Text(
              'Delete Account',
            ),
            content: const Text(
              'This action is permanent and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                  dialogContext,
                  false,
                ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(
                  dialogContext,
                  true,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color:
                    Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final user =
          client.auth.currentUser;

      if (user == null) {
        return;
      }

      await client
          .from('profiles')
          .delete()
          .eq('id', user.id);

      await client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
          const AuthScreen(),
        ),
            (_) => false,
      );
    } catch (e) {
      debugPrint(
        'DELETE ACCOUNT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete account',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    }
  }

  // =========================================================
  // OPEN EDIT PROFILE
  // =========================================================
  Future<void> openEditProfile() async {
    if (profile == null) return;

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: EditProfileScreen(
                profile: profile!,
              ),
            ),
          );
        },
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      await loadProfile();
    }
  }

  // =========================================================
  // OPEN BLOCKED USERS
  // =========================================================

  void openBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
        const BlockedUsersScreen(),
      ),
    );
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Widget buildAvatar() {
    final avatarUrl =
        profile?['avatar_url']
            ?.toString() ??
            '';

    if (avatarUrl.isNotEmpty) {
      return Container(
        padding:
        const EdgeInsets.all(
          4,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withAlpha(
                20,
              ),
              blurRadius: 20,
              offset:
              const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 58,
          backgroundColor:
          Colors.white,
          backgroundImage:
          NetworkImage(
            avatarUrl,
          ),
        ),
      );
    }

    final name =
    (profile?['name'] ??
        'NIMO User')
        .toString()
        .trim();

    final initial =
    name.isNotEmpty
        ? name[0]
        .toUpperCase()
        : 'N';

    return Container(
      padding:
      const EdgeInsets.all(
        4,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withAlpha(
              20,
            ),
            blurRadius: 20,
            offset:
            const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 58,
        backgroundColor:
        Colors.white,
        child: Text(
          initial,
          style:
          const TextStyle(
            color: primary,
            fontSize: 38,
            fontWeight:
            FontWeight
                .bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget buildStatCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets
            .symmetric(
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            22,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withAlpha(
                10,
              ),
              blurRadius: 12,
              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primary,
              size: 24,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              value.toString(),
              style:
              const TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight
                    .bold,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              title,
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
    );
  }

  // =========================================================
  // SETTING TILE
  // =========================================================

  Widget buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = primary,
    Color iconBackground =
    const Color(0xFFF0EDFF),
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withAlpha(
              8,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration:
          BoxDecoration(
            color:
            iconBackground,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style:
          const TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors
                .grey
                .shade600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons
              .arrow_forward_ios_rounded,
          size: 16,
        ),
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
    final userName =
    (profile?['name'] ??
        'NIMO User')
        .toString();

    final userEmail =
    (profile?['email'] ??
        '')
        .toString();

    final about =
    (profile?['bio'] ??
        profile?['description'] ??
        '')
        .toString()
        .trim();

    return Scaffold(
      backgroundColor:
      background,
      body:
      loading
          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          primary,
        ),
      )
          : RefreshIndicator(
        color: primary,
        onRefresh:
        loadProfile,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER
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
                      secondary,
                    ],
                    begin:
                    Alignment
                        .topLeft,
                    end:
                    Alignment
                        .bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.only(
                    bottomLeft:
                    Radius.circular(
                      34,
                    ),
                    bottomRight:
                    Radius.circular(
                      34,
                    ),
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
                            color:
                            Colors.white,
                            fontSize:
                            28,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed:
                          logout,
                          icon:
                          const Icon(
                            Icons.logout,
                            color:
                            Colors.white,
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
                      userName,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        28,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      userEmail,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color:
                        Colors.white70,
                      ),
                    ),
                    if (about
                        .isNotEmpty) ...[
                      const SizedBox(
                        height:
                        14,
                      ),
                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          14,
                          vertical:
                          12,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white.withAlpha(
                            35,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            16,
                          ),
                        ),
                        child:
                        Text(
                          about,
                          textAlign:
                          TextAlign.center,
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize:
                            14,
                            fontStyle:
                            FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width:
                      190,
                      height:
                      48,
                      child:
                      ElevatedButton.icon(
                        onPressed:
                        openEditProfile,
                        icon:
                        const Icon(
                          Icons.edit,
                          size:
                          18,
                        ),
                        label:
                        const Text(
                          'Edit Profile',
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.white,
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
                height: 24,
              ),

              // STATS
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  16,
                ),
                child: Row(
                  children: [
                    buildStatCard(
                      title:
                      'Chats',
                      value:
                      chatsCount,
                      icon:
                      Icons.chat,
                    ),
                    const SizedBox(
                      width:
                      12,
                    ),
                    buildStatCard(
                      title:
                      'Calls',
                      value:
                      callsCount,
                      icon:
                      Icons.call,
                    ),
                    const SizedBox(
                      width:
                      12,
                    ),
                    buildStatCard(
                      title:
                      'Media',
                      value:
                      mediaCount,
                      icon:
                      Icons.image,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // SETTINGS
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  16,
                ),
                child:
                Column(
                  children: [
                    buildSettingTile(
                      icon:
                      Icons.lock,
                      title:
                      'Privacy',
                      subtitle:
                      'Manage your privacy',
                      onTap:
                          () {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content:
                            Text(
                              'Coming soon',
                            ),
                            behavior:
                            SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    buildSettingTile(
                      icon:
                      Icons.block,
                      title:
                      'Blocked Users',
                      subtitle:
                      'View blocked people',
                      onTap:
                      openBlockedUsers,
                    ),
                    buildSettingTile(
                      icon:
                      Icons.help,
                      title:
                      'Help & Support',
                      subtitle:
                      'Report issues',
                      onTap:
                          () {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content:
                            Text(
                              'Coming soon',
                            ),
                            behavior:
                            SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    buildSettingTile(
                      icon:
                      Icons.delete,
                      title:
                      'Delete Account',
                      subtitle:
                      'Permanent delete',
                      iconColor:
                      Colors.red,
                      iconBackground:
                      const Color(
                        0xFFFFEBEE,
                      ),
                      onTap:
                      deleteAccount,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // LOGOUT BUTTON
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  16,
                ),
                child:
                SizedBox(
                  width:
                  double.infinity,
                  height:
                  56,
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    logout,
                    icon:
                    const Icon(
                      Icons
                          .logout,
                    ),
                    label:
                    const Text(
                      'Logout',
                      style:
                      TextStyle(
                        fontSize:
                        16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      primary,
                      foregroundColor:
                      Colors.white,
                      elevation:
                      0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}