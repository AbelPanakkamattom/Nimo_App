import 'package:flutter/material.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() =>
      _AIScreenState();
}

class _AIScreenState
    extends State<AIScreen> {
  final TextEditingController
  controller =
  TextEditingController();

  final List<Map<String, dynamic>>
  chats = [
    {
      'isMe': false,
      'message':
      'Hi 👋 I am NIMO AI. How can I help you today?',
    },
  ];

  bool typing = false;

  /// =====================================
  /// 📤 SEND MESSAGE
  /// =====================================

  Future<void> sendMessage() async {
    final text =
    controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      chats.add({
        'isMe': true,
        'message': text,
      });

      typing = true;
    });

    controller.clear();

    /// 🔥 FAKE AI RESPONSE
    await Future.delayed(
      const Duration(
        milliseconds: 1200,
      ),
    );

    if (!mounted) return;

    setState(() {
      typing = false;

      chats.add({
        'isMe': false,
        'message':
        generateReply(text),
      });
    });
  }

  /// =====================================
  /// 🤖 AI RESPONSE DEMO
  /// =====================================

  String generateReply(
      String text,
      ) {
    final lower =
    text.toLowerCase();

    if (lower.contains('hello') ||
        lower.contains('hi')) {
      return "Hello 👋 How are you?";
    }

    if (lower.contains('flutter')) {
      return "Flutter is an amazing framework for building beautiful cross-platform apps 🚀";
    }

    if (lower.contains('nimo')) {
      return "NIMO is your realtime messaging + AI platform 💜";
    }

    if (lower.contains('love')) {
      return "Love makes everything beautiful ❤️";
    }

    return "AI feature is under development 🚀";
  }

  /// =====================================
  /// 💬 CHAT BUBBLE
  /// =====================================

  Widget buildBubble({
    required bool isMe,
    required String text,
  }) {
    return Align(
      alignment:
      isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 300,
        ),
        margin:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
          isMe
              ? const Color(
            0xFF6C5CE7,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.04,
              ),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color:
            isMe
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// =====================================
  /// 🧠 FEATURE CARD
  /// =====================================

  Widget featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(
                0xFF6C5CE7,
              ).withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(
                0xFF6C5CE7,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =====================================
  /// 🎨 UI
  /// =====================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F6FF,
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.transparent,
        titleSpacing: 14,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient:
                const LinearGradient(
                  colors: [
                    Color(
                      0xFF6C5CE7,
                    ),
                    Color(
                      0xFF8E7BFF,
                    ),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              "NIMO AI",
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          /// =====================================
          /// 🔥 HERO CARD
          /// =====================================

          Container(
            margin:
            const EdgeInsets.all(
              16,
            ),
            padding:
            const EdgeInsets.all(
              24,
            ),
            decoration: BoxDecoration(
              gradient:
              const LinearGradient(
                colors: [
                  Color(
                    0xFF6C5CE7,
                  ),
                  Color(
                    0xFF8E7BFF,
                  ),
                ],
                begin:
                Alignment.topLeft,
                end:
                Alignment.bottomRight,
              ),
              borderRadius:
              BorderRadius.circular(
                28,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF6C5CE7,
                  ).withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 22,
                  offset:
                  const Offset(
                    0,
                    10,
                  ),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.15,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 42,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  "AI Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  "Your smart assistant for chatting, productivity and creativity.",
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          /// =====================================
          /// 🧠 FEATURES
          /// =====================================

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              children: [
                featureCard(
                  icon: Icons.chat,
                  title:
                  "Smart Replies",
                  subtitle:
                  "Generate instant intelligent replies.",
                ),

                featureCard(
                  icon:
                  Icons.translate,
                  title:
                  "Translation",
                  subtitle:
                  "Translate messages instantly.",
                ),

                featureCard(
                  icon:
                  Icons.edit_note,
                  title:
                  "Rewrite Messages",
                  subtitle:
                  "Improve writing using AI.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// =====================================
          /// 💬 CHAT
          /// =====================================

          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ),
              itemCount:
              chats.length +
                  (typing ? 1 : 0),
              itemBuilder: (
                  context,
                  index,
                  ) {
                if (typing &&
                    index ==
                        chats.length) {
                  return buildBubble(
                    isMe: false,
                    text: "Typing...",
                  );
                }

                final chat =
                chats[index];

                return buildBubble(
                  isMe:
                  chat['isMe'],
                  text:
                  chat['message'],
                );
              },
            ),
          ),

          /// =====================================
          /// ✍️ INPUT
          /// =====================================

          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration:
                      InputDecoration(
                        hintText:
                        "Ask AI something...",
                        filled: true,
                        fillColor:
                        const Color(
                          0xFFF1F2F6,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          18,
                          vertical:
                          14,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  GestureDetector(
                    onTap:
                    sendMessage,
                    child:
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                      const BoxDecoration(
                        color: Color(
                          0xFF6C5CE7,
                        ),
                        shape:
                        BoxShape
                            .circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color:
                        Colors.white,
                      ),
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

  /// =====================================
  /// 🧹 DISPOSE
  /// =====================================

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}