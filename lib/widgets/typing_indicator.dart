import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool visible;
  final String text;

  const TypingIndicator({
    super.key,
    this.visible = true,
    this.text = 'typing...',
  });

  @override
  State<TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  static const Color primary =
  Color(0xFF6C5CE7);

  late final AnimationController controller;
  late final Animation<double> dot1;
  late final Animation<double> dot2;
  late final Animation<double> dot3;

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
      begin: 0.25,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.6,
          curve: Curves.easeInOut,
        ),
      ),
    );

    dot2 = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.2,
          0.8,
          curve: Curves.easeInOut,
        ),
      ),
    );

    dot3 = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.4,
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );

    if (widget.visible) {
      controller.repeat();
    }
  }

  @override
  void didUpdateWidget(
      covariant TypingIndicator oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible &&
        !controller.isAnimating) {
      controller.repeat();
    } else if (!widget.visible &&
        controller.isAnimating) {
      controller.stop();
    }
  }

  Widget buildDot(
      Animation<double> animation,
      ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: Container(
          width: 8,
          height: 8,
          margin:
          const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          decoration:
          const BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Align(
        alignment:
        Alignment.centerLeft,
        child: Container(
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
                    .withAlpha(8),
                blurRadius: 8,
                offset:
                const Offset(0, 3),
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
                  fontStyle:
                  FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              buildDot(dot1),
              buildDot(dot2),
              buildDot(dot3),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}