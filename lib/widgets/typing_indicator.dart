import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool visible;
  final String text;

  const TypingIndicator({
    super.key,
    this.visible = true,
    this.text = "typing...",
  });

  @override
  State<TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<TypingIndicator>
    with
        SingleTickerProviderStateMixin {
  late AnimationController
  controller;

  late Animation<double> dot1;
  late Animation<double> dot2;
  late Animation<double> dot3;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    dot1 = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.6,
        ),
      ),
    );

    dot2 = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.2,
          0.8,
        ),
      ),
    );

    dot3 = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.4,
          1.0,
        ),
      ),
    );

    controller.repeat();
  }

  Widget buildDot(
      Animation<double> animation,
      ) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 8,
        height: 8,
        margin:
        const EdgeInsets.symmetric(
          horizontal: 2,
        ),
        decoration:
        const BoxDecoration(
          color: Color(0xFF6C5CE7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox();
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
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
                      .withAlpha(10),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    color:
                    Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 8),

                buildDot(dot1),
                buildDot(dot2),
                buildDot(dot3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }
}