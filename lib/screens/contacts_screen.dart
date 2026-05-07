import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() =>
      _ContactsScreenState();
}

class _ContactsScreenState
    extends State<ContactsScreen> {
  final SupabaseClient client =
      Supabase.instance.client;

  final TextEditingController
  searchController =
  TextEditingController();

  final TextEditingController
  nameController =
  TextEditingController();

  final TextEditingController
  emailController =
  TextEditingController();

  List<Map<String, dynamic>>
  contacts = [];

  List<Map<String, dynamic>>
  filteredContacts = [];

  bool loading = true;

  String get myId =>
      client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();

    loadContacts();

    searchController.addListener(
      filterContacts,
    );
  }

  /// ======================================
  /// 🔥 SNACKBAR
  /// ======================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  /// ======================================
  /// 📥 LOAD CONTACTS
  /// ======================================

  Future<void> loadContacts() async {
    try {
      final data = await client
          .from('contacts')
          .select()
          .eq('user_id', myId)
          .order(
        'created_at',
        ascending: false,
      );

      final unique =
      <String,
          Map<String, dynamic>>{};

      for (final item
      in List<Map<String,
          dynamic>>.from(data)) {
        final email =
        (item['contact_value'] ??
            '')
            .toString()
            .toLowerCase();

        if (!unique.containsKey(
          email,
        )) {
          unique[email] = item;
        }
      }

      contacts =
          unique.values.toList();

      filteredContacts = contacts;

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD CONTACT ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        "Failed to load contacts",
      );
    }
  }

  /// ======================================
  /// 🔍 SEARCH
  /// ======================================

  void filterContacts() {
    final query =
    searchController.text
        .trim()
        .toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredContacts = contacts;
      });

      return;
    }

    final result =
    contacts.where((contact) {
      final name =
      (contact['custom_name'] ??
          '')
          .toString()
          .toLowerCase();

      final email =
      (contact['contact_value'] ??
          '')
          .toString()
          .toLowerCase();

      return name.contains(query) ||
          email.contains(query);
    }).toList();

    setState(() {
      filteredContacts = result;
    });
  }

  /// ======================================
  /// 🔍 FIND USER
  /// ======================================

  Future<Map<String, dynamic>?>
  findUser(String email) async {
    try {
      final result = await client
          .from('profiles')
          .select()
          .ilike(
        'email',
        email.toLowerCase(),
      )
          .limit(1);

      if (result.isEmpty) {
        return null;
      }

      return result.first;
    } catch (_) {
      return null;
    }
  }

  /// ======================================
  /// ➕ ADD CONTACT
  /// ======================================

  Future<void> addContact() async {
    final name =
    nameController.text.trim();

    final email =
    emailController.text
        .trim()
        .toLowerCase();

    if (name.isEmpty ||
        email.isEmpty) {
      showMessage(
        "Fill all fields",
      );
      return;
    }

    if (email ==
        client.auth.currentUser?.email
            ?.toLowerCase()) {
      showMessage(
        "You cannot add yourself",
      );
      return;
    }

    try {
      /// DUPLICATE CHECK
      final already =
      contacts.where((c) {
        return (c['contact_value'] ??
            '')
            .toString()
            .toLowerCase() ==
            email;
      }).toList();

      if (already.isNotEmpty) {
        showMessage(
          "Contact already exists",
        );
        return;
      }

      final foundUser =
      await findUser(email);

      final data = {
        'user_id': myId,
        'custom_name': name,
        'contact_value': email,
        'created_at':
        DateTime.now()
            .toIso8601String(),
      };

      if (foundUser != null) {
        data['contact_user_id'] =
        foundUser['id'];
      }

      await client
          .from('contacts')
          .insert(data);

      nameController.clear();
      emailController.clear();

      if (!mounted) return;

      Navigator.pop(context);

      showMessage(
        "Contact added",
      );

      await loadContacts();
    } catch (e) {
      debugPrint(
        "ADD CONTACT ERROR: $e",
      );

      showMessage(
        "Failed to add contact",
      );
    }
  }

  /// ======================================
  /// ✏️ EDIT CONTACT NAME
  /// ======================================

  Future<void> editContact(
      Map<String, dynamic> contact,
      ) async {
    final controller =
    TextEditingController(
      text:
      contact['custom_name'] ??
          '',
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
          ),
          title: const Text(
            "Edit Contact",
          ),
          content: TextField(
            controller: controller,
            decoration:
            const InputDecoration(
              hintText:
              "Contact name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
              const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName =
                controller.text
                    .trim();

                if (newName
                    .isEmpty) {
                  return;
                }

                try {
                  await client
                      .from(
                    'contacts',
                  )
                      .update({
                    'custom_name':
                    newName,
                  }).eq(
                    'id',
                    contact['id'],
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.pop(
                    context,
                  );

                  showMessage(
                    "Contact updated",
                  );

                  await loadContacts();
                } catch (_) {
                  showMessage(
                    "Update failed",
                  );
                }
              },
              child:
              const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// ======================================
  /// ❌ DELETE CONTACT
  /// ======================================

  Future<void> deleteContact(
      String id,
      ) async {
    try {
      await client
          .from('contacts')
          .delete()
          .eq('id', id);

      contacts.removeWhere(
            (c) => c['id'] == id,
      );

      filterContacts();

      showMessage(
        "Contact deleted",
      );
    } catch (_) {
      showMessage(
        "Delete failed",
      );
    }
  }

  /// ======================================
  /// 🚫 BLOCK USER
  /// ======================================

  Future<void> blockUser(
      Map<String, dynamic> contact,
      ) async {
    final blockedId =
    contact['contact_user_id'];

    if (blockedId == null) {
      showMessage(
        "Cannot block",
      );
      return;
    }

    try {
      await client
          .from('blocked_users')
          .insert({
        'blocker_id': myId,
        'blocked_id': blockedId,
      });

      showMessage("User blocked");
    } catch (_) {
      showMessage(
        "Block failed",
      );
    }
  }

  /// ======================================
  /// 💬 OPEN CHAT
  /// ======================================

  void openChat(
      Map<String, dynamic> contact,
      ) {
    final userId =
    contact['contact_user_id'];

    if (userId == null) {
      showMessage(
        "User is not on NIMO",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(
              receiverId: userId,
              name:
              contact['custom_name'] ??
                  'User',
            ),
      ),
    );
  }

  /// ======================================
  /// 📤 SHARE
  /// ======================================

  Future<void> shareContact(
      String email,
      ) async {
    await Share.share(
      "Join me on NIMO 🚀\n$email",
    );
  }

  /// ======================================
  /// ➕ ADD DIALOG
  /// ======================================

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              24,
            ),
          ),
          title: const Text(
            "Add Contact",
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              TextField(
                controller:
                nameController,
                decoration:
                const InputDecoration(
                  hintText: "Name",
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              TextField(
                controller:
                emailController,
                keyboardType:
                TextInputType
                    .emailAddress,
                decoration:
                const InputDecoration(
                  hintText: "Email",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
              const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: addContact,
              child:
              const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// ======================================
  /// 👤 AVATAR
  /// ======================================

  Widget buildAvatar(
      String name,
      ) {
    return CircleAvatar(
      radius: 28,
      backgroundColor:
      const Color(0xFF6C5CE7),
      child: Text(
        name
            .substring(0, 1)
            .toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  /// ======================================
  /// UI
  /// ======================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          "Contacts",
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        const Color(
          0xFF6C5CE7,
        ),
        onPressed: showAddDialog,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
      ),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Column(
        children: [
          /// SEARCH
          Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),
            child: Container(
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),
              child: TextField(
                controller:
                searchController,
                decoration:
                const InputDecoration(
                  hintText:
                  "Search contacts",
                  prefixIcon:
                  Icon(
                    Icons.search,
                  ),
                  border:
                  InputBorder.none,
                ),
              ),
            ),
          ),

          /// EMPTY
          if (filteredContacts
              .isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 70,
                      color: Colors
                          .grey
                          .shade400,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      "No contacts found",
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child:
              ListView.builder(
                padding:
                const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 120,
                ),
                itemCount:
                filteredContacts
                    .length,
                itemBuilder:
                    (_, index) {
                  final contact =
                  filteredContacts[
                  index];

                  final hasNimo =
                      contact[
                      'contact_user_id'] !=
                          null;

                  final name =
                      contact[
                      'custom_name'] ??
                          'User';

                  final email =
                      contact[
                      'contact_value'] ??
                          '';

                  return InkWell(
                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                    onTap:
                        () => openChat(
                      contact,
                    ),
                    child: Container(
                      margin:
                      const EdgeInsets.only(
                        bottom: 14,
                      ),
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withValues(
                              alpha:
                              0.04,
                            ),
                            blurRadius:
                            10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          buildAvatar(
                            name,
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  name,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    16,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  4,
                                ),

                                Text(
                                  email,
                                  style:
                                  TextStyle(
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),

                                if (hasNimo)
                                  const Padding(
                                    padding:
                                    EdgeInsets.only(
                                      top:
                                      4,
                                    ),
                                    child:
                                    Text(
                                      "On NIMO",
                                      style:
                                      TextStyle(
                                        color:
                                        Color(
                                          0xFF6C5CE7,
                                        ),
                                        fontSize:
                                        12,
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          PopupMenuButton(
                            itemBuilder:
                                (_) => [
                              const PopupMenuItem(
                                value:
                                'edit',
                                child:
                                Text(
                                  "Edit Name",
                                ),
                              ),

                              const PopupMenuItem(
                                value:
                                'share',
                                child:
                                Text(
                                  "Share Contact",
                                ),
                              ),

                              if (hasNimo)
                                const PopupMenuItem(
                                  value:
                                  'block',
                                  child:
                                  Text(
                                    "Block User",
                                  ),
                                ),

                              const PopupMenuItem(
                                value:
                                'delete',
                                child:
                                Text(
                                  "Delete Contact",
                                ),
                              ),
                            ],
                            onSelected:
                                (
                                value,
                                ) {
                              if (value ==
                                  'edit') {
                                editContact(
                                  contact,
                                );
                              }

                              if (value ==
                                  'share') {
                                shareContact(
                                  email,
                                );
                              }

                              if (value ==
                                  'block') {
                                blockUser(
                                  contact,
                                );
                              }

                              if (value ==
                                  'delete') {
                                deleteContact(
                                  contact[
                                  'id'],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    emailController.dispose();

    super.dispose();
  }
}