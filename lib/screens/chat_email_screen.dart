// lib/screens/chat_email_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Removed unused import:
// import 'chat_detail_screen.dart';

// Corrected from your uploaded file. :contentReference[oaicite:0]{index=0}
class ChatEmailScreen extends StatefulWidget {
  const ChatEmailScreen({super.key});

  @override
  State<ChatEmailScreen> createState() =>
      _ChatEmailScreenState();
}

class _ChatEmailScreenState
    extends State<ChatEmailScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  final TextEditingController
  emailController =
  TextEditingController();

  Map<String, dynamic>? user;

  bool loading = false;

  String get myId =>
      client.auth.currentUser?.id ?? '';

  // =====================================
  // SEARCH USER
  // =====================================

  Future<void> searchUser() async {
    final email =
    emailController.text
        .trim()
        .toLowerCase();

    if (email.isEmpty) {
      showMessage(
        'Please enter email',
      );
      return;
    }

    final myEmail =
    client.auth.currentUser?.email
        ?.toLowerCase();

    if (email == myEmail) {
      showMessage(
        'You cannot search yourself',
      );
      return;
    }

    setState(() {
      loading = true;
      user = null;
    });

    try {
      final response =
      await client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      if (response == null) {
        showMessage(
          'User not found',
        );
      } else {
        setState(() {
          user = response;
        });
      }
    } catch (e) {
      showMessage(
        'Search failed',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  // =====================================
  // START CHAT
  // =====================================

  Future<void> startChat() async {
    if (user == null) {
      return;
    }

    try {
      await client
          .from('contacts')
          .upsert({
        'user_id': myId,
        'contact_user_id':
        user!['id'],
        'custom_name':
        user!['name'] ??
            'User',
        'contact_value':
        user!['email'] ??
            '',
      });

      if (!mounted) {
        return;
      }

      // Navigation to ChatDetailScreen removed
      // because the class is not found in your project.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Chat started with ${user!['name'] ?? 'User'}',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      showMessage(
        'Failed to start chat',
      );
    }
  }

  // =====================================
  // SNACKBAR
  // =====================================

  void showMessage(
      String text,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior:
        SnackBarBehavior
            .floating,
      ),
    );
  }

  // =====================================
  // USER CARD
  // =====================================

  Widget buildUserCard() {
    if (user == null) {
      return const SizedBox
          .shrink();
    }

    final avatar =
        user!['avatar_url']
            ?.toString() ??
            '';

    final name =
        user!['name']
            ?.toString() ??
            'User';

    final email =
        user!['email']
            ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withAlpha(8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // AVATAR
          avatar.isNotEmpty
              ? CircleAvatar(
            radius: 42,
            backgroundImage:
            NetworkImage(
              avatar,
            ),
          )
              : CircleAvatar(
            radius: 42,
            backgroundColor:
            const Color(
              0xFF6C5CE7,
            ),
            child: Text(
              name.isNotEmpty
                  ? name[0]
                  .toUpperCase()
                  : 'U',
              style:
              const TextStyle(
                color: Colors
                    .white,
                fontSize: 28,
                fontWeight:
                FontWeight
                    .bold,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // NAME
          Text(
            name,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // EMAIL
          Text(
            email,
            style: TextStyle(
              color: Colors
                  .grey.shade600,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // START CHAT BUTTON
          SizedBox(
            width: double.infinity,
            height: 54,
            child:
            ElevatedButton.icon(
              onPressed:
              startChat,
              icon:
              const Icon(
                Icons.chat,
              ),
              label:
              const Text(
                'Start Chat',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF6C5CE7,
                ),
                foregroundColor:
                Colors.white,
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
        ],
      ),
    );
  }

  // =====================================
  // BUILD
  // =====================================

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
          'Find by Email',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const Text(
                'Search User',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Enter email address to start chatting',
                style: TextStyle(
                  color: Colors
                      .grey
                      .shade600,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // EMAIL FIELD
              Container(
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    20,
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
                    ),
                  ],
                ),
                child:
                TextField(
                  controller:
                  emailController,
                  keyboardType:
                  TextInputType
                      .emailAddress,
                  onSubmitted:
                      (_) =>
                      searchUser(),
                  decoration:
                  const InputDecoration(
                    hintText:
                    'Enter email',
                    prefixIcon:
                    Icon(
                      Icons.email,
                    ),
                    border:
                    InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(
                      vertical:
                      18,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // SEARCH BUTTON
              SizedBox(
                width:
                double.infinity,
                height: 56,
                child:
                ElevatedButton(
                  onPressed:
                  loading
                      ? null
                      : searchUser,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF6C5CE7,
                    ),
                    foregroundColor:
                    Colors.white,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                  child:
                  loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                      strokeWidth:
                      2.5,
                    ),
                  )
                      : const Text(
                    'Search',
                    style:
                    TextStyle(
                      fontSize:
                      16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // USER CARD
              buildUserCard(),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================
  // DISPOSE
  // =====================================

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}