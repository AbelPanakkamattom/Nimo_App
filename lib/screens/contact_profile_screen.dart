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
  State<ContactProfileScreen> createState() =>
      _ContactProfileScreenState();
}

class _ContactProfileScreenState
    extends State<ContactProfileScreen> {
  static const Color primary = Color(0xFF6C5CE7);

  final SupabaseClient client =
      Supabase.instance.client;

  Map<String, dynamic>? profile;

  bool loading = true;
  bool callLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ==========================================================
  // LOAD PROFILE
  // ==========================================================
  Future<void> _loadProfile() async {
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
      debugPrint(
        'ContactProfileScreen._loadProfile error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // PROFILE DATA
  // ==========================================================
  String get name {
    final fullName =
    profile?['full_name']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final displayName =
    profile?['display_name']
        ?.toString()
        .trim();

    if (displayName != null &&
        displayName.isNotEmpty) {
      return displayName;
    }

    final customName =
    profile?['name']?.toString().trim();

    if (customName != null &&
        customName.isNotEmpty) {
      return customName;
    }

    final email =
    profile?['email']?.toString().trim();

    if (email != null &&
        email.isNotEmpty &&
        email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  String get email =>
      profile?['email']?.toString() ?? '';

  String get description {
    final desc =
    profile?['description']
        ?.toString()
        .trim();

    if (desc != null && desc.isNotEmpty) {
      return desc;
    }

    final about =
    profile?['about']
        ?.toString()
        .trim();

    if (about != null && about.isNotEmpty) {
      return about;
    }

    return 'Hey there! I am using NIMO.';
  }

  String? get avatarUrl {
    final value =
    profile?['avatar_url']
        ?.toString()
        .trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool get isOnline =>
      profile?['is_online'] == true;

  // ==========================================================
  // CALL METHODS
  // ==========================================================
  Future<void> _startVoiceCall() async {
    await _startCall(isVideo: false);
  }

  Future<void> _startVideoCall() async {
    await _startCall(isVideo: true);
  }

  Future<void> _startCall({
    required bool isVideo,
  }) async {
    if (callLoading) return;

    final currentUser =
        client.auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Please login first.',
        Colors.red,
      );
      return;
    }

    if (currentUser.id == widget.userId) {
      _showMessage(
        'You cannot call yourself.',
        Colors.red,
      );
      return;
    }

    try {
      setState(() {
        callLoading = true;
      });

      if (isVideo) {
        await ZegoCallService.startVideoCall(
          targetUserID: widget.userId,
          targetUserName: name,
        );
      } else {
        await ZegoCallService.startVoiceCall(
          targetUserID: widget.userId,
          targetUserName: name,
        );
      }

      if (!mounted) return;

      _showMessage(
        isVideo
            ? 'Starting video call with $name...'
            : 'Starting voice call with $name...',
        Colors.green,
      );
    } catch (e) {
      _showMessage(
        'Failed to start call: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          callLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================
  void _showMessage(
      String message,
      Color color,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  // ==========================================================
  // CALL BUTTON
  // ==========================================================
  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: callLoading ? null : onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient:
            const LinearGradient(
              colors: [
                Color(0xFF8B7CF8),
                primary,
              ],
            ),
            borderRadius:
            BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                primary.withAlpha(60),
                blurRadius: 12,
                offset:
                const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              if (callLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  icon,
                  color: Colors.white,
                ),
              const SizedBox(width: 8),
              Text(
                callLoading
                    ? 'Calling...'
                    : label,
                style:
                const TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE NOT FOUND
  // ==========================================================
  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user profile is unavailable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
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
      backgroundColor:
      const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        iconTheme:
        const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Contact Info',
          style: TextStyle(
            color: Colors.black,
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
          : profile == null
          ? _buildNotFound()
          : RefreshIndicator(
        onRefresh: _loadProfile,
        color: primary,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.only(
            bottom: 40,
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),

              ProfileAvatar(
                name: name,
                imageUrl:
                avatarUrl,
                radius: 60,
                isOnline:
                isOnline,
                showBorder: true,
              ),

              const SizedBox(
                height: 20,
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Text(
                  name,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight
                        .bold,
                    color:
                    Color(
                      0xFF1F1F1F,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              if (email.isNotEmpty)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    24,
                  ),
                  child: Text(
                    email,
                    textAlign:
                    TextAlign
                        .center,
                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade700,
                      fontSize:
                      15,
                    ),
                  ),
                ),

              const SizedBox(
                height: 12,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: isOnline
                      ? Colors.green
                      .withAlpha(
                      25)
                      : Colors.grey
                      .withAlpha(
                      25),
                  borderRadius:
                  BorderRadius
                      .circular(
                      20),
                ),
                child: Text(
                  isOnline
                      ? 'Online'
                      : 'Offline',
                  style:
                  TextStyle(
                    color: isOnline
                        ? Colors
                        .green
                        .shade700
                        : Colors
                        .grey
                        .shade700,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  20,
                ),
                child: Row(
                  children: [
                    _buildCallButton(
                      icon:
                      Icons.call,
                      label:
                      'Voice Call',
                      onTap:
                      _startVoiceCall,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    _buildCallButton(
                      icon: Icons
                          .videocam,
                      label:
                      'Video Call',
                      onTap:
                      _startVideoCall,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Container(
                width:
                double.infinity,
                margin:
                const EdgeInsets.symmetric(
                  horizontal:
                  20,
                ),
                padding:
                const EdgeInsets.all(
                  20,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(
                      24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withAlpha(
                          8),
                      blurRadius:
                      12,
                      offset:
                      const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .info_outline,
                          color:
                          primary,
                        ),
                        SizedBox(
                            width:
                            8),
                        Text(
                          'About',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize:
                            18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height:
                        12),
                    Text(
                      description,
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        height:
                        1.5,
                        fontSize:
                        15,
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