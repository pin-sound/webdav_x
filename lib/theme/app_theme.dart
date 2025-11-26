import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // --- Colors (Aurora Palette) ---
  static const Color primaryBlue = Color(0xFF2962FF); // Vibrant Blue
  static const Color primaryPurple = Color(0xFF6200EA); // Deep Purple
  static const Color primaryPink = Color(0xFFFF4081); // Pink Accent
  static const Color primaryTeal = Color(0xFF00BFA5); // Teal Accent

  static const Color backgroundBlue = Color(0xFFF0F4F8); // Cool Grey/Blue
  static const Color backgroundPurple = Color(0xFFF3E5F5);
  static const Color backgroundPink = Color(0xFFFCE4EC);

  static const Color textDark = Color(0xFF1A237E); // Dark Blue Grey
  static const Color textMedium = Color(0xFF5C6BC0); // Medium Indigo
  static const Color textLight = Color(0xFF9FA8DA); // Light Indigo

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF448AFF), Color(0xFF7C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF2962FF), Color(0xFFAA00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient menuUploadGradient = LinearGradient(
    colors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient menuViewGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> backgroundGradientColors = [
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE0F7FA),
  ];

  // --- Text Styles (Using GoogleFonts + System Fallback) ---
  static TextStyle get titleStyle => GoogleFonts.notoSansSc(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: 0.5,
  );

  static TextStyle get subtitleStyle => GoogleFonts.notoSansSc(
    fontSize: 14,
    color: textMedium,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get whiteTitleStyle => GoogleFonts.notoSansSc(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // --- Decorations ---
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double opacity = 0.8,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glassDecoration({
    Color color = Colors.white,
    double opacity = 0.6,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static Widget get glassAppBarFlexibleSpace {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.3),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Theme Data ---
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryPurple,
        tertiary: primaryTeal,
        surface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.notoSansScTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.notoSansSc(
          color: textDark,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: textLight.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
