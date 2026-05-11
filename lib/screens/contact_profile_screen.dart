import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/zego_call_service.dart';
import '../widgets/profile_avatarz.dart';

class ContactProfileScreen extends StatefulWidget {
  final String userId;

  const ContactProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  final SupabaseClient client = Supabase.instance.client;

  static const Color primary = Color(0xFF6C5CE7);

  Map<String, dynamic>? profile;
  bool loading = true;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ==========================================================
  // LOAD PROFILE
  // ==========================================================

  Future<void> loadProfile() async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = data == null
            ? null
            : Map<String, dynamic>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading contact profile: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // GETTERS
  // ==========================================================

  String get name {
    final value = profile?['name']?.toString().trim();
    if (value == null || value.isEmpty) {
      return 'User';
    }
    return value;
  }

  String get email {
    return profile?['email']?.toString() ?? '';
  }

  String get description {
    final value = profile?['description']?.toString().trim();
    if (value == null || value.isEmpty) {
      return 'Hey there! I am using NIMO.';
    }
    return value;
  }

  String? get avatarUrl {
    final value = profile?['avatar_url']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  bool get isOnline {
    return profile?['is_online'] == true;
  }

  // ==========================================================
  // CALL METHODS
  // IMPORTANT:
  // zego_call_service.dart uses:
  // required String targetUserID
  // (capital D)
  // ==========================================================

  Future<void> startVoiceCall() async {
    try {
      ZegoCallService.startVoiceCall(
        targetUserID: widget.userId,
        targetUserName: name,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start voice call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> startVideoCall() async {
    try {
      ZegoCallService.startVideoCall(
        targetUserID: widget.userId,
        targetUserName: name,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start video call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // NOT FOUND
  // ==========================================================

  Widget buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user profile is unavailable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CALL BUTTON
  // ==========================================================

  Widget buildCallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B7CF8),
                primary,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Contact Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      )
          : profile == null
          ? buildNotFound()
          : RefreshIndicator(
        onRefresh: loadProfile,
        color: primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // AVATAR
              ProfileAvatar(
                name: name,
                imageUrl: avatarUrl,
                radius: 60,
                isOnline: isOnline,
                showBorder: true,
              ),

              const SizedBox(height: 20),

              // NAME
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // EMAIL
              if (email.isNotEmpty)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ONLINE STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withAlpha(25)
                      : Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // CALL BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    buildCallButton(
                      icon: Icons.call,
                      label: 'Voice Call',
                      onTap: startVoiceCall,
                    ),
                    const SizedBox(width: 12),
                    buildCallButton(
                      icon: Icons.videocam,
                      label: 'Video Call',
                      onTap: startVideoCall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ABOUT CARD
              Container(
                width: double.infinity,
                margin:
                const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                        fontSize: 15,
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
}