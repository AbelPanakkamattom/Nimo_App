import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/profile_avatarz.dart';
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

  static const Color primary =
  Color(0xFF6C5CE7);

  String get myId =>
      client.auth.currentUser?.id ?? '';

  String get myEmail =>
      client.auth.currentUser?.email
          ?.toLowerCase() ??
          '';

  @override
  void initState() {
    super.initState();
    loadContacts();
    searchController.addListener(
      filterContacts,
    );
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor: primary,
      ),
    );
  }

  // ==========================================
  // LOAD CONTACTS
  // ==========================================

  Future<void> loadContacts() async {
    if (myId.isEmpty) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    try {
      final response =
      await client
          .from('contacts')
          .select()
          .eq('user_id', myId)
          .order(
        'created_at',
        ascending: false,
      );

      final unique = <
          String,
          Map<String, dynamic>>{};

      for (final item
      in List<Map<String,
          dynamic>>.from(
        response,
      )) {
        final email =
        (item['contact_value'] ??
            '')
            .toString()
            .toLowerCase();

        if (email.isNotEmpty) {
          unique[email] = item;
        }
      }

      contacts =
          unique.values.toList();

      filteredContacts =
      List<Map<String,
          dynamic>>.from(
        contacts,
      );
    } catch (e) {
      showMessage(
        'Failed to load contacts.',
      );
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ==========================================
  // FILTER
  // ==========================================

  void filterContacts() {
    final query =
    searchController.text
        .trim()
        .toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        filteredContacts =
        List<Map<String,
            dynamic>>.from(
          contacts,
        );
      } else {
        filteredContacts =
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

              return name
                  .contains(query) ||
                  email.contains(query);
            }).toList();
      }
    });
  }

  // ==========================================
  // FIND USER BY EMAIL
  // ==========================================

  Future<Map<String, dynamic>?>
  findUserByEmail(
      String email,
      ) async {
    try {
      final result =
      await client
          .from('profiles')
          .select()
          .ilike(
        'email',
        email,
      )
          .limit(1);

      if (result.isEmpty) {
        return null;
      }

      return Map<String,
          dynamic>.from(
        result.first,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // ADD CONTACT
  // ==========================================

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
        'Please fill all fields.',
      );
      return;
    }

    if (email == myEmail) {
      showMessage(
        'You cannot add yourself.',
      );
      return;
    }

    final alreadyExists =
    contacts.any(
          (contact) =>
      (contact['contact_value'] ??
          '')
          .toString()
          .toLowerCase() ==
          email,
    );

    if (alreadyExists) {
      showMessage(
        'Contact already exists.',
      );
      return;
    }

    try {
      final foundUser =
      await findUserByEmail(
        email,
      );

      final data =
      <String, dynamic>{
        'user_id': myId,
        'custom_name': name,
        'contact_value': email,
        'created_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      };

      if (foundUser != null &&
          foundUser['id'] != null) {
        data['contact_user_id'] =
        foundUser['id'];
      }

      await client
          .from('contacts')
          .insert(data);

      if (!mounted) return;

      Navigator.pop(context);

      nameController.clear();
      emailController.clear();

      showMessage(
        'Contact added.',
      );

      await loadContacts();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      showMessage(
        'Failed to add contact.',
      );
    }
  }

  // ==========================================
  // EDIT CONTACT
  // ==========================================

  Future<void> editContact(
      Map<String, dynamic> contact,
      ) async {
    final controller =
    TextEditingController(
      text:
      contact['custom_name']
          ?.toString() ??
          '',
    );

    final result =
    await showDialog<bool>(
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
            'Edit Contact',
          ),
          content: TextField(
            controller: controller,
            decoration:
            const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final newName =
    controller.text.trim();

    if (newName.isEmpty) {
      return;
    }

    try {
      await client
          .from('contacts')
          .update({
        'custom_name':
        newName,
      })
          .eq(
        'id',
        contact['id'],
      );

      showMessage(
        'Contact updated.',
      );

      await loadContacts();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      showMessage(
        'Failed to update contact.',
      );
    }
  }

  // ==========================================
  // DELETE CONTACT
  // ==========================================

  Future<void> deleteContact(
      String id,
      ) async {
    try {
      await client
          .from('contacts')
          .delete()
          .eq('id', id);

      contacts.removeWhere(
            (contact) =>
        contact['id']
            .toString() ==
            id,
      );

      filterContacts();

      showMessage(
        'Contact deleted.',
      );
    } catch (_) {
      showMessage(
        'Failed to delete contact.',
      );
    }
  }

  // ==========================================
  // BLOCK USER
  // ==========================================

  Future<void> blockUser(
      Map<String, dynamic> contact,
      ) async {
    final blockedId =
    contact['contact_user_id']
        ?.toString();

    if (blockedId == null ||
        blockedId.isEmpty) {
      showMessage(
        'This user is not on NIMO.',
      );
      return;
    }

    try {
      await client
          .from('blocked_users')
          .upsert({
        'blocker_id': myId,
        'blocked_id':
        blockedId,
      });

      showMessage(
        'User blocked.',
      );
    } catch (_) {
      showMessage(
        'Failed to block user.',
      );
    }
  }

  // ==========================================
  // SHARE
  // ==========================================

  Future<void> shareContact(
      String email,
      ) async {
    await Share.share(
      'Join me on NIMO 🚀\n$email',
    );
  }

  // ==========================================
  // OPEN CHAT
  // ==========================================

  void openChat(
      Map<String, dynamic> contact,
      ) {
    final otherUserId =
    contact['contact_user_id']
        ?.toString();

    if (otherUserId == null ||
        otherUserId.isEmpty) {
      showMessage(
        'This user is not on NIMO.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(
              otherUserId:
              otherUserId,
              otherUserName:
              (contact['custom_name'] ??
                  'User')
                  .toString(),
              otherUserAvatar:
              '',
            ),
      ),
    );
  }

  // ==========================================
  // ADD CONTACT DIALOG
  // ==========================================

  void showAddDialog() {
    nameController.clear();
    emailController.clear();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              28,
            ),
          ),
          child: Padding(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Text(
                  'Add Contact',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller:
                  nameController,
                  decoration:
                  const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(
                      Icons.person,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                TextField(
                  controller:
                  emailController,
                  keyboardType:
                  TextInputType
                      .emailAddress,
                  decoration:
                  const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width:
                  double.infinity,
                  height: 50,
                  child:
                  ElevatedButton(
                    onPressed:
                    addContact,
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      primary,
                    ),
                    child:
                    const Text(
                      'Save Contact',
                      style:
                      TextStyle(
                        color: Colors
                            .white,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        foregroundColor:
        Colors.black,
        title: const Text(
          'Contacts',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton(
        onPressed:
        showAddDialog,
        backgroundColor:
        primary,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
      ),
      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(
          color: primary,
        ),
      )
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),
            child: TextField(
              controller:
              searchController,
              decoration:
              InputDecoration(
                hintText:
                'Search contacts',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                filled: true,
                fillColor:
                Colors.white,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
            filteredContacts
                .isEmpty
                ? Center(
              child:
              Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .people_outline,
                    size:
                    72,
                    color: Colors
                        .grey
                        .shade400,
                  ),
                  const SizedBox(
                    height:
                    16,
                  ),
                  Text(
                    'No Contacts Found',
                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                      fontSize:
                      16,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh:
              loadContacts,
              color:
              primary,
              child:
              ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  120,
                ),
                itemCount:
                filteredContacts.length,
                itemBuilder:
                    (
                    context,
                    index,
                    ) {
                  final contact =
                  filteredContacts[index];

                  final name =
                  (contact['custom_name'] ??
                      'User')
                      .toString();

                  final email =
                  (contact['contact_value'] ??
                      '')
                      .toString();

                  final hasNimo =
                      contact['contact_user_id'] !=
                          null;

                  return Container(
                    margin:
                    const EdgeInsets.only(
                      bottom:
                      12,
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
                          color: Colors.black.withAlpha(
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
                    ListTile(
                      onTap:
                          () =>
                          openChat(
                            contact,
                          ),
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        14,
                        vertical:
                        8,
                      ),
                      leading:
                      ProfileAvatar(
                        name:
                        name,
                        radius:
                        28,
                        showOnlineStatus:
                        false,
                      ),
                      title:
                      Text(
                        name,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      subtitle:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                          ),
                          if (hasNimo)
                            const Text(
                              'On NIMO',
                              style:
                              TextStyle(
                                color:
                                primary,
                                fontSize:
                                12,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      trailing:
                      PopupMenuButton<
                          String>(
                        onSelected:
                            (
                            value,
                            ) {
                          switch (
                          value) {
                            case 'edit':
                              editContact(
                                contact,
                              );
                              break;
                            case 'share':
                              shareContact(
                                email,
                              );
                              break;
                            case 'block':
                              blockUser(
                                contact,
                              );
                              break;
                            case 'delete':
                              deleteContact(
                                contact['id']
                                    .toString(),
                              );
                              break;
                          }
                        },
                        itemBuilder:
                            (
                            context,
                            ) =>
                        [
                          const PopupMenuItem(
                            value:
                            'edit',
                            child:
                            Text(
                              'Edit Name',
                            ),
                          ),
                          const PopupMenuItem(
                            value:
                            'share',
                            child:
                            Text(
                              'Share Contact',
                            ),
                          ),
                          if (hasNimo)
                            const PopupMenuItem(
                              value:
                              'block',
                              child:
                              Text(
                                'Block User',
                              ),
                            ),
                          const PopupMenuItem(
                            value:
                            'delete',
                            child:
                            Text(
                              'Delete Contact',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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