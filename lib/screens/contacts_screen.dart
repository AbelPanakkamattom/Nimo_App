import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/profile_avatarz.dart';
import 'chat_detail_screen.dart';
import 'contact_profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterUsers);
    searchController.dispose();
    super.dispose();
  }

  // ===============================================================
  // LOAD USERS FROM SUPABASE
  // ===============================================================
  Future<void> _loadUsers() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId ?? '')
          .order('name', ascending: true);

      final users = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      setState(() {
        allUsers = users;
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load contacts: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===============================================================
  // SEARCH FILTER
  // ===============================================================
  void _filterUsers() {
    final query = searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final name = _getUserName(user).toLowerCase();
          final email = _getUserEmail(user).toLowerCase();

          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  // ===============================================================
  // HELPERS
  // ===============================================================
  String _getUserName(Map<String, dynamic> user) {
    final name = (user['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final email = (user['email'] ?? '').toString().trim();
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Unknown User';
  }

  String _getUserEmail(Map<String, dynamic> user) {
    return (user['email'] ?? '').toString();
  }

  String _getUserAvatar(Map<String, dynamic> user) {
    return (user['avatar_url'] ?? '').toString();
  }

  bool _isUserOnline(Map<String, dynamic> user) {
    return user['is_online'] == true;
  }

  // ===============================================================
  // NAVIGATION
  // ===============================================================
  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          otherUserId: user['id'].toString(),
          otherUserName: _getUserName(user),
          otherUserAvatar: _getUserAvatar(user),
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactProfileScreen(
          userId: user['id'].toString(),
        ),
      ),
    );
  }

  // ===============================================================
  // SEARCH BAR
  // ===============================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // CONTACT TILE
  // ===============================================================
  Widget _buildContactTile(Map<String, dynamic> user) {
    final name = _getUserName(user);
    final email = _getUserEmail(user);
    final avatar = _getUserAvatar(user);
    final online = _isUserOnline(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () => _openChat(user),
        onLongPress: () => _openProfile(user),
        leading: ProfileAvatar(
          name: name,
          imageUrl: avatar,
          radius: 26,
          isOnline: online,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'chat') {
              _openChat(user);
            } else if (value == 'profile') {
              _openProfile(user);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'chat',
              child: Text('Open Chat'),
            ),
            PopupMenuItem(
              value: 'profile',
              child: Text('View Profile'),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // BODY
  // ===============================================================
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          searchController.text.trim().isEmpty
              ? 'No contacts found'
              : 'No matching contacts',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          ...filteredUsers.map(_buildContactTile),
        ],
      ),
    );
  }

  // ===============================================================
  // UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Contacts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
}