import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final client = Supabase.instance.client;

  final nameController = TextEditingController();
  final descController = TextEditingController();

  final picker = ImagePicker();

  File? image;
  bool loading = false;
  bool imageLoading = false;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.profile['username'] ?? '';
    descController.text = widget.profile['description'] ?? '';
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
    } catch (e) {
      showMessage("Failed to pick image");
    }
  }

  /// 📤 UPLOAD IMAGE
  Future<String?> uploadImage(String userId) async {
    final storage = client.storage.from('avatarz');
    final path = "$userId/profile.jpg";

    try {
      /// No new image → keep old
      if (image == null) {
        return widget.profile['avatar_url'];
      }

      setState(() => imageLoading = true);

      /// Delete old image (ignore errors)
      try {
        await storage.remove([path]);
      } catch (_) {}

      /// Upload new image
      await storage.upload(
        path,
        image!,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      /// Force refresh image URL
      final url =
          "${storage.getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}";

      return url;
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      showMessage("Image upload failed");
      return widget.profile['avatar_url'];
    } finally {
      if (mounted) setState(() => imageLoading = false);
    }
  }

  /// 💾 SAVE PROFILE
  Future<void> saveProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage("Session expired");
      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage("Name required");
      return;
    }

    if (loading) return;

    setState(() => loading = true);

    try {
      final imageUrl = await uploadImage(user.id);

      final response = await client
          .from('profiles')
          .update({
        'username': name,
        'description': descController.text.trim(),
        'avatar_url': imageUrl,
      })
          .eq('id', user.id)
          .select(); // 🔥 IMPORTANT

      if (response.isEmpty) {
        showMessage("Update failed (no row affected)");
        return;
      }

      if (!mounted) return;

      showMessage("Profile updated");

      Navigator.pop(context, true); // ✅ trigger refresh
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
      showMessage("Update failed");
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
    final avatarUrl = widget.profile['avatar_url'];

    ImageProvider? avatarProvider;

    if (image != null) {
      avatarProvider = FileImage(image!);
    } else if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
      avatarProvider = NetworkImage(avatarUrl);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// PROFILE IMAGE
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF6C5CE7),
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(Icons.person,
                        size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                if (imageLoading)
                  const CircularProgressIndicator(),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              "Tap to change photo",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

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

            const SizedBox(height: 30),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}