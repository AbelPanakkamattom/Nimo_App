import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String name;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.name,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final client = Supabase.instance.client;
  final messageController = TextEditingController();

  String get myId => client.auth.currentUser!.id;

  /// 🔥 FIXED STREAM (MANUAL SORT)
  Stream<List<Map<String, dynamic>>> getMessages() {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) {
      final filtered = data.where((m) {
        return (m['sender_id'] == myId &&
            m['receiver_id'] == widget.receiverId) ||
            (m['sender_id'] == widget.receiverId &&
                m['receiver_id'] == myId);
      }).toList();

      /// ✅ VERY IMPORTANT FIX (SORT BY TIME)
      filtered.sort((a, b) {
        final aTime = DateTime.parse(a['created_at']);
        final bTime = DateTime.parse(b['created_at']);
        return bTime.compareTo(aTime); // latest first
      });

      return filtered;
    });
  }

  /// 📤 SEND MESSAGE
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    await client.from('messages').insert({
      'sender_id': myId,
      'receiver_id': widget.receiverId,
      'content': text,
      'status': 'sent',
    });
  }

  /// 👀 MARK SEEN
  Future<void> markSeen() async {
    await client
        .from('messages')
        .update({'status': 'seen'})
        .eq('sender_id', widget.receiverId)
        .eq('receiver_id', myId)
        .neq('status', 'seen');
  }

  /// 💬 MESSAGE UI
  Widget bubble(Map msg) {
    final isMe = msg['sender_id'] == myId;

    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:
        const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF6C5CE7)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),

      appBar: AppBar(
        title: Text(widget.name),
      ),

      body: Column(
        children: [
          /// 💬 CHAT
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                      child: Text("No messages yet"));
                }

                markSeen();

                return ListView.builder(
                  reverse: true, // 🔥 IMPORTANT
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => bubble(messages[i]),
                );
              },
            ),
          ),

          /// ✍️ INPUT
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}