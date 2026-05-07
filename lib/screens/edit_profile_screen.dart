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
  final SupabaseClient client = Supabase.instance.client;

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController bioController =
  TextEditingController();

  final ImagePicker picker = ImagePicker();

  File? selectedImage;

  bool loading = false;
  bool imageLoading = false;

  @override
  void initState() {
    super.initState();

    nameController.text =
        widget.profile['name']?.toString() ??
            widget.profile['username']?.toString() ??
            '';

    bioController.text =
        widget.profile['description']?.toString() ??
            '';
  }

  /// =========================
  /// 🔥 SNACKBAR
  /// =========================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// =========================
  /// 📸 PICK IMAGE
  /// =========================

  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (picked == null) return;

      if (!mounted) return;

      setState(() {
        selectedImage = File(picked.path);
      });
    } catch (e) {
      showMessage("Failed to pick image");
    }
  }

  /// =========================
  /// 📤 UPLOAD IMAGE
  /// =========================

  Future<String?> uploadAvatar(String userId) async {
    try {
      if (selectedImage == null) {
        return widget.profile['avatar_url'];
      }

      if (mounted) {
        setState(() {
          imageLoading = true;
        });
      }

      final storage = client.storage.from('avatarz');

      final path =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await storage.upload(
        path,
        selectedImage!,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      final url =
          '${storage.getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';

      return url;
    } catch (e) {
      debugPrint("IMAGE ERROR: $e");
      showMessage("Image upload failed");
      return widget.profile['avatar_url'];
    } finally {
      if (mounted) {
        setState(() {
          imageLoading = false;
        });
      }
    }
  }

  /// =========================
  /// 💾 SAVE PROFILE
  /// =========================

  Future<void> saveProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage("Session expired");
      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage("Name is required");
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final avatarUrl = await uploadAvatar(user.id);

      await client
          .from('profiles')
          .update({
        'name': name,
        'description': bioController.text.trim(),
        'avatar_url': avatarUrl,
      })
          .eq('id', user.id);

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated"),
        ),
      );
    } catch (e) {
      debugPrint("PROFILE UPDATE ERROR: $e");

      if (!mounted) return;

      showMessage("Failed to update profile");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =========================
  /// 🖼 AVATAR
  /// =========================

  Widget buildAvatar() {
    final avatarUrl =
    widget.profile['avatar_url']?.toString();

    ImageProvider? provider;

    if (selectedImage != null) {
      provider = FileImage(selectedImage!);
    } else if (avatarUrl != null &&
        avatarUrl.isNotEmpty) {
      provider = NetworkImage(avatarUrl);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF6C5CE7),
            backgroundImage: provider,
            child: provider == null
                ? const Icon(
              Icons.person,
              color: Colors.white,
              size: 55,
            )
                : null,
          ),
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        if (imageLoading)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// =========================
  /// 🧱 UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// PROFILE IMAGE
              buildAvatar(),

              const SizedBox(height: 14),

              const Text(
                "Tap photo to change",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 35),

              /// NAME
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: nameController,
                  textCapitalization:
                  TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Your name",
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ABOUT
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "About you",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        bottom: 65,
                      ),
                      child: Icon(Icons.info_outline),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                  loading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }
}