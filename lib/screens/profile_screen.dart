import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart'; // 🔥 NEW

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final client = Supabase.instance.client;

  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  /// ============================
  /// 🔥 LOAD PROFILE
  /// ============================
  Future<void> loadProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        profile = null;
      });
      return;
    }

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }

  /// ============================
  /// 🚪 LOGOUT
  /// ============================
  Future<void> logout() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
    );
  }

  /// ============================
  /// ❌ DELETE ACCOUNT
  /// ============================
  Future<void> deleteAccount() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This action is permanent. All your data will be deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await client.from('profiles').delete().eq('id', user.id);
      await client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete account")),
      );
    }
  }

  /// ============================
  /// ✏️ EDIT PROFILE
  /// ============================
  Future<void> openEditProfile() async {
    if (profile == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile!),
      ),
    );

    if (updated == true && mounted) {
      setState(() {
        loading = true;
      });
      await loadProfile();
    }
  }

  /// ============================
  /// 🚫 BLOCKED USERS
  /// ============================
  void openBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BlockedUsersScreen(),
      ),
    );
  }

  /// ============================
  /// 🖼 AVATAR
  /// ============================
  ImageProvider? getAvatar() {
    final url = profile?['avatar_url'];

    if (url == null || url.toString().isEmpty) return null;

    return NetworkImage(
      "$url?t=${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  /// ============================
  /// 🎨 UI
  /// ============================
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? const Center(child: Text("No profile found"))
          : RefreshIndicator(
        onRefresh: loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// HEADER
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, Color(0xFF8E7BFF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.white),
                          onPressed: logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// PROFILE CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -60),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: primary,
                          backgroundImage: getAvatar(),
                          child: getAvatar() == null
                              ? const Icon(Icons.person,
                              size: 55, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile?['username'] ?? "No Name",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile?['email'] ?? "",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: openEditProfile,
                            child: const Text("Edit Profile"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// OPTIONS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    profileTile(Icons.lock, "Privacy", () {}),
                    profileTile(Icons.block, "Blocked Users",
                        openBlockedUsers),
                    profileTile(Icons.report, "Report Issues", () {}),

                    const SizedBox(height: 20),

                    /// DELETE ACCOUNT
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: deleteAccount,
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete Account"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// LOGOUT
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileTile(
      IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C5CE7)),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}