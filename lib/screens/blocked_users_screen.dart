import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final client = Supabase.instance.client;

  List blocked = [];

  @override
  void initState() {
    super.initState();
    loadBlocked();
  }

  Future<void> loadBlocked() async {
    final res = await client
        .from('blocked_users')
        .select()
        .eq('blocker_id', client.auth.currentUser!.id);

    if (!mounted) return;

    setState(() => blocked = res);
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  Future<void> unblock(String id) async {
    await client.from('blocked_users').delete().match({
      'blocker_id': client.auth.currentUser!.id,
      'blocked_id': id,
    });

    loadBlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Users")),
      body: blocked.isEmpty
          ? const Center(child: Text("No blocked users"))
          : ListView.builder(
        itemCount: blocked.length,
        itemBuilder: (_, i) {
          final userId = blocked[i]['blocked_id'];

          return FutureBuilder(
            future: getUser(userId),
            builder: (_, snap) {
              final user = snap.data ?? {};

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(user['username'] ?? "User"),
                trailing: TextButton(
                  onPressed: () => unblock(userId),
                  child: const Text("Unblock"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}