import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import 'auth_screen.dart';
import 'blocked_users_screen.dart';
import 'edit_profile_screen.dart';
import 'email_screen.dart';
import 'starred_messages_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  static const Color primary =
  Color(0xFF6C5CE7);
  static const Color secondary =
  Color(0xFF8E7BFF);

  bool notifications = true;
  bool readReceipts = true;

  Map<String, dynamic> profile = {};

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
    final user = client.auth.currentUser;

    if (user == null) return;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = data ??
            {
              'id': user.id,
              'name':
              user.userMetadata?['name'] ??
                  user.email
                      ?.split('@')
                      .first ??
                  'NIMO User',
              'email': user.email ?? '',
              'bio':
              user.userMetadata?['bio'] ??
                  '',
              'avatar_url':
              user.userMetadata?[
              'avatar_url'] ??
                  '',
            };
      });
    } catch (e) {
      debugPrint(
        'SETTINGS PROFILE LOAD ERROR: $e',
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
        builder: (_) =>
        const AuthScreen(),
      ),
          (_) => false,
    );
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor: primary,
      ),
    );
  }

  // =========================================================
  // CONFIRM LOGOUT
  // =========================================================

  Future<void> confirmLogout() async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
          ),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from NIMO?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    false,
                  ),
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    true,
                  ),
              child: const Text(
                'Logout',
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

    if (result == true) {
      await logout();
    }
  }

  // =========================================================
  // OPEN EDIT PROFILE
  // =========================================================

  Future<void> openEditProfile() async {
    final result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(
              profile: profile,
            ),
      ),
    );

    if (result == true) {
      await loadProfile();

      if (!mounted) return;

      showMessage(
        'Profile updated successfully.',
      );
    }
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget buildProfileCard() {
    final userName =
    (profile['name'] ??
        profile['username'] ??
        'NIMO User')
        .toString();

    final userEmail =
    (profile['email'] ?? '')
        .toString();

    final avatarUrl =
    (profile['avatar_url'] ?? '')
        .toString();

    final initial =
    userName.trim().isNotEmpty
        ? userName
        .trim()[0]
        .toUpperCase()
        : 'N';

    ImageProvider? imageProvider;

    if (avatarUrl.isNotEmpty) {
      imageProvider =
          NetworkImage(avatarUrl);
    }

    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            primary,
            secondary,
          ],
          begin:
          Alignment.topLeft,
          end: Alignment
              .bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(
          28,
        ),
        boxShadow: [
          BoxShadow(
            color: primary
                .withAlpha(70),
            blurRadius: 24,
            offset:
            const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor:
            Colors.white
                .withAlpha(
              40,
            ),
            backgroundImage:
            imageProvider,
            child:
            imageProvider ==
                null
                ? Text(
              initial,
              style:
              const TextStyle(
                color: Colors
                    .white,
                fontSize:
                28,
                fontWeight:
                FontWeight
                    .bold,
              ),
            )
                : null,
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color: Colors
                        .white,
                    fontSize: 22,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color: Colors
                        .white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
            openEditProfile,
            icon: const Icon(
              Icons.edit,
              color:
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget buildSectionTitle(
      String title,
      ) {
    final isDark =
        Theme.of(context)
            .brightness ==
            Brightness.dark;

    return Padding(
      padding:
      const EdgeInsets.only(
        top: 4,
        bottom: 14,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight:
          FontWeight.bold,
          color: isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }

  // =========================================================
  // TILE
  // =========================================================

  Widget buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color iconColor = primary,
    Color iconBackground =
    const Color(0xFFF0EDFF),
  }) {
    final theme =
    Theme.of(context);
    final isDark =
        theme.brightness ==
            Brightness.dark;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? primary.withAlpha(
              20,
            )
                : Colors.black
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
            BorderRadius
                .circular(
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
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight
                .w600,
            color: theme
                .textTheme
                .bodyLarge
                ?.color,
          ),
        ),
        subtitle:
        subtitle == null
            ? null
            : Text(
          subtitle,
          style:
          TextStyle(
            color: theme
                .textTheme
                .bodyMedium
                ?.color
                ?.withAlpha(
              180,
            ),
          ),
        ),
        trailing: trailing,
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
    final theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        surfaceTintColor:
        Colors.transparent,
        foregroundColor:
        theme
            .appBarTheme
            .foregroundColor,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding:
        const EdgeInsets
            .all(20),
        children: [
          // PROFILE CARD
          buildProfileCard(),

          const SizedBox(
            height: 28,
          ),

          // ACCOUNT
          buildSectionTitle(
            'Account',
          ),

          buildTile(
            icon: Icons.person,
            title:
            'Edit Profile',
            subtitle:
            'Update your personal information',
            trailing:
            const Icon(
              Icons
                  .arrow_forward_ios,
              size: 16,
            ),
            onTap:
            openEditProfile,
          ),

          buildTile(
            icon:
            Icons
                .star_border,
            title:
            'Starred Messages',
            subtitle:
            'View saved messages',
            trailing:
            const Icon(
              Icons
                  .arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                  const StarredMessagesScreen(),
                ),
              );
            },
          ),

          buildTile(
            icon: Icons.block,
            title:
            'Blocked Users',
            subtitle:
            'Manage blocked contacts',
            trailing:
            const Icon(
              Icons
                  .arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                  const BlockedUsersScreen(),
                ),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // CHAT SETTINGS
          buildSectionTitle(
            'Chat Settings',
          ),

          buildTile(
            icon: Icons
                .notifications,
            title:
            'Notifications',
            subtitle:
            'Message alerts and sounds',
            trailing: Switch(
              value:
              notifications,
              activeThumbColor:
              primary,
              onChanged:
                  (value) {
                setState(() {
                  notifications =
                      value;
                });
              },
            ),
          ),

          buildTile(
            icon:
            Icons.done_all,
            title:
            'Read Receipts',
            subtitle:
            'Show when messages are read',
            trailing: Switch(
              value:
              readReceipts,
              activeThumbColor:
              primary,
              onChanged:
                  (value) {
                setState(() {
                  readReceipts =
                      value;
                });
              },
            ),
          ),

          // DARK MODE (WORKING)
          buildTile(
            icon:
            Icons.dark_mode,
            title:
            'Dark Mode',
            subtitle:
            'Switch between light and dark theme',
            trailing:
            Consumer<
                ThemeProvider>(
              builder: (
                  context,
                  themeProvider,
                  child,
                  ) {
                return Switch(
                  value:
                  themeProvider
                      .isDarkMode,
                  activeThumbColor:
                  primary,
                  onChanged:
                      (value) async {
                    await themeProvider
                        .toggleTheme(
                      value,
                    );

                    if (!mounted) {
                      return;
                    }

                    showMessage(
                      value
                          ? 'Dark mode enabled'
                          : 'Light mode enabled',
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // SUPPORT
          buildSectionTitle(
            'Support',
          ),

          buildTile(
            icon: Icons
                .email_outlined,
            title:
            'Contact Support',
            subtitle:
            'Send us an email',
            trailing:
            const Icon(
              Icons
                  .arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                  const EmailScreen(),
                ),
              );
            },
          ),

          buildTile(
            icon: Icons
                .info_outline,
            title:
            'About NIMO',
            subtitle:
            'Version 1.0.0',
          ),

          const SizedBox(
            height: 30,
          ),

          // LOGOUT BUTTON
          SizedBox(
            height: 56,
            child:
            ElevatedButton
                .icon(
              onPressed:
              confirmLogout,
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                Colors.red,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              icon:
              const Icon(
                Icons.logout,
                color: Colors
                    .white,
              ),
              label:
              const Text(
                'Logout',
                style:
                TextStyle(
                  color: Colors
                      .white,
                  fontWeight:
                  FontWeight
                      .bold,
                  fontSize:
                  16,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}