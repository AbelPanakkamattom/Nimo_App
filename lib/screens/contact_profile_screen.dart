import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseClient client =
      Supabase.instance.client;

  Map<String, dynamic>? profile;

  bool loading = true;

  static const Color primary =
  Color(0xFF6C5CE7);

  // ==========================================
  // INIT
  // ==========================================

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ==========================================
  // LOAD PROFILE
  // ==========================================

  Future<void> loadProfile() async {
    try {
      final data =
      await client
          .from('profiles')
          .select()
          .eq(
        'id',
        widget.userId,
      )
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = data == null
            ? null
            : Map<String,
            dynamic>.from(
          data,
        );
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================
  // GETTERS
  // ==========================================

  String get name {
    final value =
    profile?['name']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return 'User';
    }

    return value;
  }

  String get email {
    return profile?['email']
        ?.toString() ??
        '';
  }

  String get description {
    final value =
    profile?['description']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return 'Hey there! I am using NIMO.';
    }

    return value;
  }

  String? get avatarUrl {
    final value =
    profile?['avatar_url']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  bool get isOnline {
    return profile?['is_online'] ==
        true;
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget buildNotFound() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .person_off_outlined,
              size: 72,
              color: Colors
                  .grey
                  .shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'Profile Not Found',
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
              'This user profile is unavailable.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors
                    .grey
                    .shade600,
              ),
            ),
          ],
        ),
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
      const Color(
        0xFFF5F6FF,
      ),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          'Contact Info',
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
          : profile == null
          ? buildNotFound()
          : RefreshIndicator(
        onRefresh:
        loadProfile,
        color: primary,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child:
          Column(
            children: [
              const SizedBox(
                height:
                30,
              ),

              // AVATAR
              ProfileAvatar(
                name:
                name,
                imageUrl:
                avatarUrl,
                radius:
                60,
                isOnline:
                isOnline,
                showBorder:
                true,
              ),

              const SizedBox(
                height:
                20,
              ),

              // NAME
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  24,
                ),
                child:
                Text(
                  name,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize:
                    26,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                height:
                8,
              ),

              // EMAIL
              if (email
                  .isNotEmpty)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    24,
                  ),
                  child:
                  Text(
                    email,
                    textAlign:
                    TextAlign.center,
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
                height:
                12,
              ),

              // ONLINE STATUS
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  14,
                  vertical:
                  6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  isOnline
                      ? Colors.green.withAlpha(
                    30,
                  )
                      : Colors.grey.withAlpha(
                    30,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                Text(
                  isOnline
                      ? 'Online'
                      : 'Offline',
                  style:
                  TextStyle(
                    color:
                    isOnline
                        ? Colors.green
                        : Colors.grey,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(
                height:
                30,
              ),

              // ABOUT
              Container(
                width:
                double.infinity,
                margin:
                const EdgeInsets.all(
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
                  BorderRadius.circular(
                    24,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withAlpha(
                        8,
                      ),
                      blurRadius:
                      10,
                      offset:
                      const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize:
                        18,
                      ),
                    ),
                    const SizedBox(
                      height:
                      12,
                    ),
                    Text(
                      description,
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        height:
                        1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}