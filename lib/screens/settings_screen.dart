import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';

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

  bool notifications = true;
  bool darkMode = false;
  bool readReceipts = true;

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

  Widget buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(
              0xFF6C5CE7,
            ).withAlpha(25),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
          child: const Icon(
            Icons.settings,
            color: Color(0xFF6C5CE7),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding:
        const EdgeInsets.all(20),
        children: [
          /// ACCOUNT
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          buildTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle:
            'Manage your profile',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),

          buildTile(
            icon: Icons.lock,
            title: 'Privacy',
            subtitle:
            'Privacy and security',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),

          buildTile(
            icon: Icons.storage,
            title: 'Storage',
            subtitle:
            'Manage app storage',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),

          const SizedBox(height: 24),

          /// CHAT SETTINGS
          const Text(
            'Chat Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          buildTile(
            icon:
            Icons.notifications,
            title: 'Notifications',
            trailing: Switch(
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications =
                      value;
                });
              },
            ),
          ),

          buildTile(
            icon: Icons.done_all,
            title: 'Read Receipts',
            trailing: Switch(
              value: readReceipts,
              onChanged: (value) {
                setState(() {
                  readReceipts =
                      value;
                });
              },
            ),
          ),

          buildTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: darkMode,
              onChanged: (value) {
                setState(() {
                  darkMode = value;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          /// SUPPORT
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          buildTile(
            icon: Icons.help,
            title: 'Help Center',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),

          buildTile(
            icon: Icons.info,
            title: 'About Nimo',
            subtitle:
            'Version 1.0.0',
          ),

          const SizedBox(height: 30),

          /// LOGOUT
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: logout,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}