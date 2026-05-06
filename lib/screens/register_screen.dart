import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'auth_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  const RegisterScreen({
    super.key,
    required this.email,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  final picker = ImagePicker();
  final client = Supabase.instance.client;

  File? image;
  bool loading = false;

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 🔥 LOGOUT + GO TO LOGIN
  Future<void> _logoutAndGoLogin() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
    );
  }

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked != null && mounted) {
        setState(() => image = File(picked.path));
      }
    } catch (_) {
      showMessage("Failed to pick image");
    }
  }

  /// 📤 UPLOAD IMAGE
  Future<String?> uploadImage(String userId) async {
    if (image == null) return null;

    try {
      final storage = client.storage.from('avatarz');
      final path = "$userId/profile.jpg";

      await storage.upload(
        path,
        image!,
        fileOptions: const FileOptions(upsert: true),
      );

      return "${storage.getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      showMessage("Image upload failed");
      return null;
    }
  }

  /// 💾 CREATE PROFILE
  Future<void> saveProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage("Session expired. Please login again.");
      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage("Enter your name");
      return;
    }

    if (loading) return;

    setState(() => loading = true);

    try {
      final imageUrl = await uploadImage(user.id);

      final email = (user.email ?? widget.email).toLowerCase();

      await client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'username': name,
        'avatar_url': imageUrl ?? "",
        'description': descController.text.trim(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");
      showMessage("Failed to save profile");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      /// ✅ HANDLE SYSTEM BACK (ANDROID BACK BUTTON)
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _logoutAndGoLogin();
        }
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FF),

        appBar: AppBar(
          title: const Text("Create Profile"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _logoutAndGoLogin,
          ),
        ),

        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// PROFILE IMAGE
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFEAEAFF),
                        backgroundImage:
                        image != null ? FileImage(image!) : null,
                        child: image == null
                            ? const Icon(Icons.person, size: 45)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Tap to add profile photo",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                /// EMAIL
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.email)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// NAME
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Enter your name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 20),

                /// DESCRIPTION
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "About you",
                    prefixIcon: Icon(Icons.info),
                  ),
                ),

                const SizedBox(height: 35),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : saveProfile,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Create Account"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}