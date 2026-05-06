import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_screen.dart';

class ChatEmailScreen extends StatefulWidget {
  const ChatEmailScreen({super.key});

  @override
  State<ChatEmailScreen> createState() => _ChatEmailScreenState();
}

class _ChatEmailScreenState extends State<ChatEmailScreen> {
  final client = Supabase.instance.client;

  final TextEditingController emailController = TextEditingController();

  Map<String, dynamic>? user;
  bool loading = false;

  String get myId => client.auth.currentUser!.id;

  /// ============================
  /// 🔍 SEARCH USER (EXACT)
  /// ============================
  Future<void> searchUser() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _show("Enter email");
      return;
    }

    if (client.auth.currentUser?.email?.toLowerCase() == email) {
      _show("You cannot search yourself");
      return;
    }

    setState(() {
      loading = true;
      user = null;
    });

    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (res == null) {
        _show("User not found");
      } else {
        user = res;
      }
    } catch (e) {
      _show("Search failed");
    }

    if (mounted) setState(() => loading = false);
  }

  /// ============================
  /// 💬 START CHAT
  /// ============================
  Future<void> startChat() async {
    if (user == null) return;

    try {
      /// ✅ SAVE CONTACT (CORRECT STRUCTURE)
      await client.from('contacts').upsert({
        'user_id': myId,
        'contact_id': user!['id'],
        'custom_name': user!['name'] ?? "User",
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            receiverId: user!['id'],
            name: user!['name'] ?? "User",
          ),
        ),
      );
    } catch (e) {
      _show("Failed to start chat");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  /// ============================
  /// 🎨 UI
  /// ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Start Chat"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 📧 EMAIL INPUT
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter email",
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔍 SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : searchUser,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Search"),
              ),
            ),

            const SizedBox(height: 30),

            /// 👤 USER RESULT
            if (user != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                      (user!['avatar_url'] != null &&
                          user!['avatar_url']
                              .toString()
                              .isNotEmpty)
                          ? NetworkImage(user!['avatar_url'])
                          : null,
                      child: (user!['avatar_url'] == null ||
                          user!['avatar_url']
                              .toString()
                              .isEmpty)
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      user!['name'] ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: startChat,
                        child: const Text("Start Chat"),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}