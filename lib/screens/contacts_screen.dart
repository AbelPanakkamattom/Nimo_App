import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'chat_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final client = Supabase.instance.client;

  List<Map<String, dynamic>> contacts = [];
  bool loading = true;

  final nameController = TextEditingController();
  final valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 🔹 LOAD CONTACTS
  Future<void> loadContacts() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return;

      final data = await client
          .from('contacts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        contacts = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      showMessage("Failed to load contacts");
    }
  }

  /// 🔍 FIND USER (FIXED)
  Future<Map<String, dynamic>?> findUser(String value) async {
    try {
      final email = value.trim().toLowerCase();

      final res = await client
          .from('profiles')
          .select()
          .ilike('email', email)
          .maybeSingle();

      return res;
    } catch (_) {
      return null;
    }
  }

  /// ➕ ADD CONTACT (FIXED)
  Future<void> addContact() async {
    final user = client.auth.currentUser;

    final name = nameController.text.trim();
    final value = valueController.text.trim().toLowerCase();

    if (name.isEmpty || value.isEmpty) {
      showMessage("Fill all fields");
      return;
    }

    /// ❌ prevent adding yourself
    if (user?.email?.toLowerCase() == value) {
      showMessage("You cannot add yourself");
      return;
    }

    try {
      final foundUser = await findUser(value);

      /// ✅ CHECK DUPLICATE
      final existing = await client
          .from('contacts')
          .select()
          .eq('user_id', user!.id)
          .eq('contact_value', value)
          .maybeSingle();

      if (existing != null) {
        showMessage("Contact already exists");
        return;
      }

      await client.from('contacts').insert({
        'user_id': user.id,
        'contact_user_id': foundUser?['id'],
        'contact_value': value,
        'custom_name': name,
      });

      if (!mounted) return;

      Navigator.pop(context);

      nameController.clear();
      valueController.clear();

      showMessage("Contact added");
      loadContacts();
    } catch (e) {
      debugPrint("ADD CONTACT ERROR: $e");
      showMessage("Failed to add contact");
    }
  }

  /// 📤 INVITE
  void invite(String value) {
    SharePlus.instance.share(
      ShareParams(
        text: "Hey! Join my app 🚀\nDownload: https://yourapp.link\nContact: $value",
        subject: "Join my app 🚀",
      ),
    );
  }

  /// ➕ ADD DIALOG
  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Custom name",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                hintText: "Email",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: addContact,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// 💬 OPEN CHAT
  void openChat(Map contact) {
    if (contact['contact_user_id'] == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          receiverId: contact['contact_user_id'],
          name: contact['custom_name'],
        ),
      ),
    );
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
          ? const Center(child: Text("No contacts yet"))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final c = contacts[index];

          final hasAccount =
              c['contact_user_id'] != null;

          final name = c['custom_name'] ?? "";
          final value = c['contact_value'] ?? "";

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                name.isNotEmpty
                    ? name[0].toUpperCase()
                    : "?",
              ),
            ),
            title: Text(name),
            subtitle: Text(value),

            /// 🔥 FIXED ACTION
            trailing: hasAccount
                ? ElevatedButton(
              onPressed: () => openChat(c),
              child: const Text("Chat"),
            )
                : TextButton(
              onPressed: () => invite(value),
              child: const Text("Invite"),
            ),
          );
        },
      ),
    );
  }
}