import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final client = Supabase.instance.client;

  String searchText = "";

  String get myId => client.auth.currentUser!.id;

  /// ============================
  /// 🔥 STREAM ONLY MY MESSAGES
  /// ============================
  Stream<List<Map<String, dynamic>>> getMessages() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return data.where((m) =>
      m['sender_id'] == myId ||
          m['receiver_id'] == myId).toList();
    });
  }

  /// ============================
  /// 💬 GROUP CONVERSATIONS
  /// ============================
  List<Map<String, dynamic>> groupChats(List messages) {
    final map = <String, Map<String, dynamic>>{};

    for (var m in messages) {
      final otherId =
      m['sender_id'] == myId ? m['receiver_id'] : m['sender_id'];

      if (!map.containsKey(otherId)) {
        map[otherId] = m;
      }
    }

    return map.values.toList();
  }

  /// ============================
  /// 👤 FETCH USER NAME (LIVE)
  /// ============================
  Future<Map<String, dynamic>?> getProfile(String id) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  String formatTime(String t) {
    final d = DateTime.parse(t);
    return "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  /// ============================
  /// 🎨 UI
  /// ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) =>
                  setState(() => searchText = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search chats...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔴 STREAM
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = groupChats(snapshot.data!);

                if (chats.isEmpty) {
                  return const Center(child: Text("No chats yet"));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final msg = chats[i];

                    final otherId = msg['sender_id'] == myId
                        ? msg['receiver_id']
                        : msg['sender_id'];

                    return FutureBuilder(
                      future: getProfile(otherId),
                      builder: (_, snap) {
                        final profile = snap.data;
                        final name = profile?['name'] ?? "User";

                        /// 🔍 SEARCH FILTER
                        if (searchText.isNotEmpty &&
                            !name.toLowerCase().contains(searchText)) {
                          return const SizedBox();
                        }

                        return _chatTile(msg, name, otherId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ============================
  /// 💬 CHAT TILE
  /// ============================
  Widget _chatTile(Map msg, String name, String id) {
    final isMe = msg['sender_id'] == myId;

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF6C5CE7),
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name),
      subtitle: Row(
        children: [
          if (isMe)
            Icon(
              msg['status'] == 'seen'
                  ? Icons.done_all
                  : Icons.check,
              size: 14,
              color: msg['status'] == 'seen'
                  ? Colors.blue
                  : Colors.grey,
            ),
          if (isMe) const SizedBox(width: 4),
          Expanded(
            child: Text(
              msg['content'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Text(
        formatTime(msg['created_at']),
        style: const TextStyle(fontSize: 11),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(receiverId: id, name: name),
          ),
        );
      },
    );
  }
}