import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() =>
      _AIScreenState();
}

class _AIScreenState
    extends State<AIScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color primary =
  Color(0xFF6C5CE7);

  static const Color secondary =
  Color(0xFF8E7BFF);

  static const Color background =
  Color(0xFFF5F6FF);

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController
  _controller =
  TextEditingController();

  final ScrollController
  _scrollController =
  ScrollController();

  // =========================================================
  // AI MODEL
  // =========================================================

  GenerativeModel? _model;

  // =========================================================
  // STATES
  // =========================================================

  bool _isLoading = false;

  final List<_AIMessage>
  _messages = [
    const _AIMessage(
      isMe: false,
      text:
      'Hi 👋 I am NIMO AI.\nHow can I help you today?',
    ),
  ];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  // =========================================================
  // INITIALIZE GEMINI AI
  // =========================================================

  void _initializeAI() {
    try {
      final apiKey =
      dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null ||
          apiKey.isEmpty) {
        debugPrint(
          'GEMINI_API_KEY missing',
        );
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      debugPrint(
        'GEMINI AI INITIALIZED',
      );
    } catch (e) {
      debugPrint(
        'AI INIT ERROR: $e',
      );
    }
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {
    final text =
    _controller.text.trim();

    if (text.isEmpty ||
        _isLoading) {
      return;
    }

    setState(() {
      _messages.add(
        _AIMessage(
          isMe: true,
          text: text,
        ),
      );

      _isLoading = true;
    });

    _controller.clear();

    _scrollToBottom();

    try {
      String prompt = text;

      // -----------------------------------------------------
      // SMART REPLIES
      // -----------------------------------------------------

      if (text.startsWith(
        'SMART_REPLY:',
      )) {
        final content = text.replaceFirst(
          'SMART_REPLY:',
          '',
        );

        prompt = '''
Generate 5 short smart replies for this message:

$content
''';
      }

      // -----------------------------------------------------
      // TRANSLATION
      // -----------------------------------------------------

      else if (text.startsWith(
        'TRANSLATE:',
      )) {
        final content = text.replaceFirst(
          'TRANSLATE:',
          '',
        );

        prompt = '''
Translate this text into English:

$content
''';
      }

      // -----------------------------------------------------
      // REWRITE
      // -----------------------------------------------------

      else if (text.startsWith(
        'REWRITE:',
      )) {
        final content = text.replaceFirst(
          'REWRITE:',
          '',
        );

        prompt = '''
Rewrite this professionally:

$content
''';
      }

      // -----------------------------------------------------
      // EMAIL
      // -----------------------------------------------------

      else if (text.startsWith(
        'EMAIL:',
      )) {
        final content = text.replaceFirst(
          'EMAIL:',
          '',
        );

        prompt = '''
Write a professional email for:

$content
''';
      }

      // -----------------------------------------------------
      // GENERAL QA
      // -----------------------------------------------------

      else if (text.startsWith(
        'QUESTION:',
      )) {
        final content = text.replaceFirst(
          'QUESTION:',
          '',
        );

        prompt = '''
Answer this question clearly:

$content
''';
      }

      // -----------------------------------------------------
      // NORMAL CHAT
      // -----------------------------------------------------

      final response =
      await _model!.generateContent([
        Content.text(prompt),
      ]);

      final reply =
          response.text ??
              'No response generated';

      if (!mounted) return;

      setState(() {
        _messages.add(
          _AIMessage(
            isMe: false,
            text: reply,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _AIMessage(
            isMe: false,
            text:
            'AI Error:\n\n$e',
          ),
        );
      });
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
  }

  // =========================================================
  // FEATURE BUTTON
  // =========================================================

  void _selectFeature(
      String type,
      ) {
    switch (type) {
      case 'reply':
        _controller.text =
        'SMART_REPLY: ';
        break;

      case 'translate':
        _controller.text =
        'TRANSLATE: ';
        break;

      case 'rewrite':
        _controller.text =
        'REWRITE: ';
        break;

      case 'email':
        _controller.text =
        'EMAIL: ';
        break;

      case 'qa':
        _controller.text =
        'QUESTION: ';
        break;
    }

    _controller.selection =
        TextSelection.fromPosition(
          TextPosition(
            offset:
            _controller.text.length,
          ),
        );
  }

  // =========================================================
  // SCROLL
  // =========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController
          .hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration: const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // =========================================================
  // FEATURE CARD
  // =========================================================

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        22,
      ),
      child: Container(
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
            22,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withAlpha(
                8,
              ),
              blurRadius: 12,
              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primary.withAlpha(
                  20,
                ),
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: primary,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
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
                      fontSize: 17,
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
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MESSAGE BUBBLE
  // =========================================================

  Widget _messageBubble(
      _AIMessage message,
      ) {
    final isMe = message.isMe;

    return Align(
      alignment:
      isMe
          ? Alignment
          .centerRight
          : Alignment
          .centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 320,
        ),
        margin:
        const EdgeInsets.symmetric(
          horizontal: 16,
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
              ? primary
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withAlpha(
                8,
              ),
              blurRadius: 8,
              offset:
              const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color:
            isMe
                ? Colors.white
                : Colors.black87,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HERO CARD
  // =========================================================

  Widget _heroCard() {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        20,
      ),
      padding:
      const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            primary,
            secondary,
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          28,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color:
              Colors.white.withAlpha(
                30,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'NIMO AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Smart AI assistant powered by Gemini',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INPUT AREA
  // =========================================================
  Widget _inputArea() {
    const double bottomNavHeight = 92;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + bottomNavHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask AI something...',
                  filled: true,
                  fillColor: background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      background,

      appBar: AppBar(
        backgroundColor:
        background,
        elevation: 0,
        title: const Text(
          'NIMO AI',
          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller:
              _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _heroCard(),
                ),

                SliverPadding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 16,
                  ),
                  sliver: SliverList(
                    delegate:
                    SliverChildListDelegate(
                      [
                        _featureCard(
                          icon: Icons
                              .chat_bubble_outline,
                          title:
                          'Smart Replies',
                          subtitle:
                          'Generate intelligent replies',
                          onTap:
                              () =>
                              _selectFeature(
                                'reply',
                              ),
                        ),

                        _featureCard(
                          icon: Icons
                              .translate,
                          title:
                          'Translation',
                          subtitle:
                          'Translate any text',
                          onTap:
                              () =>
                              _selectFeature(
                                'translate',
                              ),
                        ),

                        _featureCard(
                          icon: Icons
                              .edit_note,
                          title:
                          'Rewrite Messages',
                          subtitle:
                          'Rewrite professionally',
                          onTap:
                              () =>
                              _selectFeature(
                                'rewrite',
                              ),
                        ),

                        _featureCard(
                          icon: Icons
                              .email_outlined,
                          title:
                          'Email Writing',
                          subtitle:
                          'Write professional emails',
                          onTap:
                              () =>
                              _selectFeature(
                                'email',
                              ),
                        ),

                        _featureCard(
                          icon:
                          Icons.help_outline,
                          title:
                          'General Q&A',
                          subtitle:
                          'Ask any question',
                          onTap:
                              () =>
                              _selectFeature(
                                'qa',
                              ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                SliverList(
                  delegate:
                  SliverChildBuilderDelegate(
                        (
                        context,
                        index,
                        ) {
                      return _messageBubble(
                        _messages[index],
                      );
                    },
                    childCount:
                    _messages.length,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 20,
                  ),
                ),
              ],
            ),
          ),

          _inputArea(),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// =========================================================
// AI MESSAGE MODEL
// =========================================================

class _AIMessage {
  final bool isMe;
  final String text;

  const _AIMessage({
    required this.isMe,
    required this.text,
  });
}