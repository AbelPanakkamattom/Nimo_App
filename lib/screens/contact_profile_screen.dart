import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        profile = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  String getName() {
    if (profile == null) return 'User';

    final name = profile!['name'];

    if (name == null) return 'User';

    return name.toString();
  }

  String getEmail() {
    if (profile == null) return '';

    final email = profile!['email'];

    if (email == null) return '';

    return email.toString();
  }

  String getDescription() {
    if (profile == null) return '';

    final description =
    profile!['description'];

    if (description == null) {
      return 'Hey there! I am using Nimo.';
    }

    return description.toString();
  }

  String getAvatar() {
    if (profile == null) return '';

    final avatar =
    profile!['avatar_url'];

    if (avatar == null) return '';

    return avatar.toString();
  }

  bool isOnline() {
    if (profile == null) return false;

    return profile!['is_online'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Contact Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            /// AVATAR
            getAvatar().isNotEmpty
                ? CircleAvatar(
              radius: 60,
              backgroundImage:
              NetworkImage(
                getAvatar(),
              ),
            )
                : CircleAvatar(
              radius: 60,
              backgroundColor:
              const Color(
                0xFF6C5CE7,
              ),
              child: Text(
                getName()[0]
                    .toUpperCase(),
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 40,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// NAME
            Text(
              getName(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            /// EMAIL
            Text(
              getEmail(),
              style: TextStyle(
                color:
                Colors.grey.shade700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            /// ONLINE STATUS
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isOnline()
                    ? Colors.green
                    .withAlpha(30)
                    : Colors.grey
                    .withAlpha(30),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                isOnline()
                    ? 'Online'
                    : 'Offline',
                style: TextStyle(
                  color: isOnline()
                      ? Colors.green
                      : Colors.grey,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ABOUT
            Container(
              width: double.infinity,
              margin:
              const EdgeInsets.all(
                20,
              ),
              padding:
              const EdgeInsets.all(
                20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  24,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(
                      height: 12),

                  Text(
                    getDescription(),
                    style: TextStyle(
                      color: Colors
                          .grey.shade700,
                      height: 1.5,
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