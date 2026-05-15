import 'package:flutter/material.dart';

class AppThemeHelper {
  AppThemeHelper._();

  // =========================================================
  // BACKGROUND COLORS
  // =========================================================

  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color card(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  // =========================================================
  // TEXT COLORS
  // =========================================================

  static Color text(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  // =========================================================
  // PRIMARY COLORS
  // =========================================================

  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  // =========================================================
  // INPUT COLORS
  // =========================================================

  static Color inputFill(BuildContext context) {
    return Theme.of(context).inputDecorationTheme.fillColor ??
        Theme.of(context).cardColor;
  }

  // =========================================================
  // ICON COLORS
  // =========================================================

  static Color icon(BuildContext context) {
    return Theme.of(context).iconTheme.color ??
        Theme.of(context).colorScheme.onSurface;
  }

  // =========================================================
  // DIVIDER COLORS
  // =========================================================

  static Color divider(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  // =========================================================
  // CHAT COLORS
  // =========================================================

  static Color myMessage(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color otherMessage(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  // =========================================================
  // STATUS COLORS
  // =========================================================

  static Color success(BuildContext context) {
    return Colors.green;
  }

  static Color error(BuildContext context) {
    return Colors.red;
  }

  static Color warning(BuildContext context) {
    return Colors.orange;
  }

  // =========================================================
  // BOOLEAN HELPERS
  // =========================================================

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static bool isLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }
}