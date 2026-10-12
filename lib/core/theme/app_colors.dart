import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryDark = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFF6C63FF); // Deep Iris
  static const Color accent = Color(0xFF00F5A0); // Neon Mint

  // Backgrounds
  static const Color background = Color(0xFF0A0E1A); // Deep Night Navy
  static const Color surface = Color(0xFF131B2E); // Dark Slate Blue
  static const Color surfaceCard = Color(0xFF182238); // Elevated Card Surface
  static const Color inputField = Color(0xFF1C2844); // Input Container

  // Borders & Dividers
  static const Color border = Color(0xFF263556);
  static const Color borderFocused = Color(0xFF00E5FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E9BB5);
  static const Color textMuted = Color(0xFF5A6882);

  // Status & Feedback
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0F172A), Color(0xFF0B1021)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x331C2844), Color(0x1A141D30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
