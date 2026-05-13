import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/contact_service.dart';
import '../widgets/profile_avatarz.dart';
import 'chat_detail_screen.dart';
import 'contact_profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() =>
      _ContactsScreenState();
}

class _ContactsScreenState
    extends State<ContactsScreen> {
  static const Color primary =
  Color(0xFF6C5CE7);

  static const Color background =
  Color(0xFFF5F6FF);

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController
  _searchController =
  TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PROFILE HELPERS
  // ==========================================================
  Future<Map<String, dynamic>?> _getProfile(
      String userId,
      ) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(
        response,
      );
    } catch (_) {
      return null;
    }
  }

  String _getEmail(
      Map<String, dynamic>? profile,
      ) {
    return profile?['email']
        ?.toString() ??
        '';
  }

  String? _getAvatar(
      Map<String, dynamic>? profile,
      ) {
    final value = profile?['avatar_url']
        ?.toString()
        .trim();

    if (value == null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  bool _isOnline(
      Map<String, dynamic>? profile,
      ) {
    return profile?['is_online'] ==
        true;
  }

  // ==========================================================
  // FILTER CONTACTS
  // ==========================================================
  List<ContactModel> _filterContacts(
      List<ContactModel> contacts,
      ) {
    if (_searchQuery.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      return contact.displayName
          .toLowerCase()
          .contains(
        _searchQuery,
      ) ||
          contact.contactValue
              .toLowerCase()
              .contains(
            _searchQuery,
          );
    }).toList();
  }

  // ==========================================================
  // OPEN CHAT
  // ==========================================================
  void _openChat({
    required ContactModel contact,
    required Map<String, dynamic>?
    profile,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          otherUserId:
          contact.contactUserId,
          otherUserName:
          contact.displayName,
          otherUserAvatar:
          _getAvatar(profile),
        ),
      ),
    );
  }

  // ==========================================================
  // OPEN PROFILE
  // ==========================================================
  void _openProfile(
      ContactModel contact,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContactProfileScreen(
              userId:
              contact.contactUserId,
            ),
      ),
    );
  }

  // ==========================================================
  // ADD CONTACT
  // ==========================================================
  Future<void>
  _showAddContactDialog() async {
    final emailController =
    TextEditingController();

    final nameController =
    TextEditingController();

    try {
      final result =
      await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title:
              const Text('Add Contact'),
              content: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                    emailController,
                    keyboardType:
                    TextInputType
                        .emailAddress,
                    autocorrect: false,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Email Address',
                      hintText:
                      'example@gmail.com',
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller:
                    nameController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Custom Name',
                      hintText:
                      'Daddy, Appa, Mom, Friend',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        false,
                      ),
                  child:
                  const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        true,
                      ),
                  child:
                  const Text('Save'),
                ),
              ],
            ),
      );

      if (result != true) {
        return;
      }

      final email =
      emailController.text
          .trim()
          .toLowerCase();

      final customName =
      nameController.text.trim();

      if (email.isEmpty) {
        _showSnack(
          'Please enter an email address.',
          isError: true,
        );
        return;
      }

      await ContactService
          .addContactByEmail(
        email: email,
        customName: customName,
      );

      _showSnack(
        'Contact added successfully.',
      );
    } catch (e) {
      String message =
      e.toString();

      if (message.startsWith(
        'Exception: ',
      )) {
        message =
            message.replaceFirst(
              'Exception: ',
              '',
            );
      }

      _showSnack(
        message,
        isError: true,
      );
    } finally {
      emailController.dispose();
      nameController.dispose();
    }
  }

  // ==========================================================
  // RENAME CONTACT
  // ==========================================================
  Future<void> _showRenameDialog(
      ContactModel contact,
      ) async {
    final controller =
    TextEditingController(
      text: contact.displayName,
    );

    try {
      final result =
      await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text(
                'Rename Contact',
              ),
              content: TextField(
                controller: controller,
                decoration:
                const InputDecoration(
                  labelText:
                  'Custom Name',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        false,
                      ),
                  child:
                  const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        true,
                      ),
                  child:
                  const Text('Save'),
                ),
              ],
            ),
      );

      if (result != true) {
        return;
      }

      final newName =
      controller.text.trim();

      if (newName.isEmpty) {
        _showSnack(
          'Name cannot be empty.',
          isError: true,
        );
        return;
      }

      await ContactService
          .updateContactName(
        contactId: contact.id,
        displayName: newName,
      );

      _showSnack(
        'Contact renamed successfully.',
      );
    } catch (e) {
      _showSnack(
        e.toString(),
        isError: true,
      );
    }
  }

  // ==========================================================
  // DELETE CONTACT
  // ==========================================================
  Future<void> _deleteContact(
      ContactModel contact,
      ) async {
    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title:
            const Text('Delete Contact'),
            content: Text(
              'Delete "${contact.displayName}" from your contacts?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text('Cancel'),
              ),
              ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                ),
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                child:
                const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await ContactService
          .deleteContact(
        contact.id,
      );

      _showSnack(
        'Contact deleted.',
      );
    } catch (e) {
      _showSnack(
        e.toString(),
        isError: true,
      );
    }
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================
  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  // ==========================================================
  // SEARCH BAR
  // ==========================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withAlpha(
              10,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller:
        _searchController,
        onChanged: (value) {
          if (!mounted) {
            return;
          }

          setState(() {
            _searchQuery = value
                .trim()
                .toLowerCase();
          });
        },
        decoration: const InputDecoration(
          hintText:
          'Search contacts...',
          prefixIcon:
          Icon(Icons.search),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================
  Widget _buildEmptyState({
    required bool searching,
  }) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              searching
                  ? Icons
                  .search_off_rounded
                  : Icons
                  .contacts_outlined,
              size: 72,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              searching
                  ? 'No Matching Contacts'
                  : 'No Contacts Yet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              searching
                  ? 'Try a different search term.'
                  : 'Tap + to add a contact.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors
                    .grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONTACT TILE
  // ==========================================================
  Widget _buildContactTile(
      ContactModel contact,
      ) {
    return FutureBuilder<
        Map<String, dynamic>?>(
      future:
      _getProfile(
        contact.contactUserId,
      ),
      builder: (
          context,
          snapshot,
          ) {
        final profile =
            snapshot.data;

        final email =
        _getEmail(profile);

        final avatar =
        _getAvatar(profile);

        final online =
        _isOnline(profile);

        return Container(
          margin:
          const EdgeInsets.only(
            bottom: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              26,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha(12),
                blurRadius: 12,
                offset:
                const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () => _openChat(
              contact: contact,
              profile: profile,
            ),
            leading: ProfileAvatar(
              name:
              contact.displayName,
              imageUrl: avatar,
              radius: 26,
              isOnline: online,
            ),
            title: Text(
              contact.displayName,
              style: const TextStyle(
                fontWeight:
                FontWeight.w700,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              email.isNotEmpty
                  ? email
                  : contact
                  .contactValue,
              maxLines: 1,
              overflow:
              TextOverflow
                  .ellipsis,
            ),
            trailing:
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'chat':
                    _openChat(
                      contact: contact,
                      profile: profile,
                    );
                    break;

                  case 'profile':
                    _openProfile(
                      contact,
                    );
                    break;

                  case 'rename':
                    _showRenameDialog(
                      contact,
                    );
                    break;

                  case 'delete':
                    _deleteContact(
                      contact,
                    );
                    break;
                }
              },
              itemBuilder: (context) =>
              const [
                PopupMenuItem(
                  value: 'chat',
                  child:
                  Text('Open Chat'),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child:
                  Text('View Profile'),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(
                    'Set Name / Rename',
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Contact',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================
  Widget _buildBody() {
    return StreamBuilder<
        List<ContactModel>>(
      stream:
      ContactService.watchContacts(),
      builder: (
          context,
          snapshot,
          ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(
              color: primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load contacts.\n${snapshot.error}',
              textAlign:
              TextAlign.center,
            ),
          );
        }

        final contacts =
            snapshot.data ?? [];

        final filtered =
        _filterContacts(
          contacts,
        );

        if (contacts.isEmpty) {
          return _buildEmptyState(
            searching: false,
          );
        }

        return ListView(
          padding:
          const EdgeInsets.all(20),
          children: [
            _buildSearchBar(),
            const SizedBox(
              height: 20,
            ),
            if (filtered.isEmpty)
              _buildEmptyState(
                searching: true,
              )
            else
              ...filtered.map(
                _buildContactTile,
              ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      background,
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
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton:
      FloatingActionButton(
        heroTag: 'contacts_fab',
        backgroundColor: primary,
        onPressed: _showAddContactDialog,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
      ),
    );
  }
}