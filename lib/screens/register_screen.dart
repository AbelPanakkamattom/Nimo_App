import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  const RegisterScreen({
    super.key,
    required this.email,
  });

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  final ImagePicker picker = ImagePicker();

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController bioController =
  TextEditingController();

  File? selectedImage;

  bool loading = false;
  bool imageLoading = false;

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
  /// 🚪 LOGOUT
  /// =========================

  Future<void> logout() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
          (_) => false,
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

  Future<String?> uploadAvatar(
      String userId,
      ) async {
    try {
      if (selectedImage == null) {
        return null;
      }

      if (mounted) {
        setState(() {
          imageLoading = true;
        });
      }

      final storage =
      client.storage.from('avatarz');

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
      debugPrint("UPLOAD ERROR: $e");

      showMessage("Image upload failed");

      return null;
    } finally {
      if (mounted) {
        setState(() {
          imageLoading = false;
        });
      }
    }
  }

  /// =========================
  /// 💾 CREATE PROFILE
  /// =========================

  Future<void> createProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage(
        "Session expired. Login again.",
      );
      return;
    }

    final name =
    nameController.text.trim();

    if (name.isEmpty) {
      showMessage("Enter your name");
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final avatarUrl =
      await uploadAvatar(user.id);

      await client
          .from('profiles')
          .upsert({
        'id': user.id,
        'email': widget.email
            .trim()
            .toLowerCase(),
        'name': name,
        'description':
        bioController.text.trim(),
        'avatar_url': avatarUrl ?? '',
        'created_at': DateTime.now()
            .toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const HomeScreen(),
        ),
            (_) => false,
      );
    } catch (e) {
      debugPrint("REGISTER ERROR: $e");

      showMessage(
        "Failed to create profile",
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =========================
  /// 🖼 PROFILE IMAGE
  /// =========================

  Widget buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundColor:
            const Color(0xFF6C5CE7),
            backgroundImage:
            selectedImage != null
                ? FileImage(
              selectedImage!,
            )
                : null,
            child: selectedImage == null
                ? const Icon(
              Icons.person,
              size: 55,
              color: Colors.white,
            )
                : null,
          ),
        ),

        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding:
            const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
              const Color(0xFF6C5CE7),
              borderRadius:
              BorderRadius.circular(
                30,
              ),
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
              color: Colors.black
                  .withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child:
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult:
          (didPop, result) async {
        if (!didPop) {
          await logout();
        }
      },

      child: Scaffold(
        backgroundColor:
        const Color(0xFFF5F6FF),

        appBar: AppBar(
          elevation: 0,
          backgroundColor:
          Colors.transparent,

          title: const Text(
            "Create Profile",
            style: TextStyle(
              color: Colors.black,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          leading: IconButton(
            icon:
            const Icon(Icons.arrow_back),
            onPressed: logout,
          ),
        ),

        body: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },

          child: SafeArea(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.all(22),

              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),

                  /// AVATAR
                  buildAvatar(),

                  const SizedBox(
                    height: 14,
                  ),

                  const Text(
                    "Tap to add profile photo",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  /// EMAIL CARD
                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color:
                          Color(
                            0xFF6C5CE7,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Text(
                            widget.email,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  /// NAME
                  Container(
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child: TextField(
                      controller:
                      nameController,
                      textCapitalization:
                      TextCapitalization
                          .words,
                      decoration:
                      const InputDecoration(
                        hintText:
                        "Your name",
                        prefixIcon:
                        Icon(
                          Icons.person,
                        ),
                        border:
                        InputBorder
                            .none,
                        contentPadding:
                        EdgeInsets.symmetric(
                          horizontal:
                          16,
                          vertical:
                          18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  /// BIO
                  Container(
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child: TextField(
                      controller:
                      bioController,
                      maxLines: 4,
                      decoration:
                      const InputDecoration(
                        hintText:
                        "About you",
                        prefixIcon:
                        Padding(
                          padding:
                          EdgeInsets.only(
                            bottom: 65,
                          ),
                          child: Icon(
                            Icons.info_outline,
                          ),
                        ),
                        border:
                        InputBorder
                            .none,
                        contentPadding:
                        EdgeInsets.symmetric(
                          horizontal:
                          16,
                          vertical:
                          18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ),

                  /// BUTTON
                  SizedBox(
                    width:
                    double.infinity,
                    height: 56,
                    child:
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : createProfile,

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

                      child: loading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.5,
                          color: Colors
                              .white,
                        ),
                      )
                          : const Text(
                        "Create Account",
                        style:
                        TextStyle(
                          fontSize:
                          16,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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