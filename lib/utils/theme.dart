import 'package:flutter/material.dart';

class AppTheme {
  // Academic Core - Color Palette (Updated)
  static const Color primary = Color(0xFF3F51B5); // Royal Indigo (#3F51B5)
  static const Color primaryDark = Color(0xFF24389C); // Dark Royal Indigo
  static const Color secondary = Color(0xFF00BCD4); // Cyan (#00BCD4)
  static const Color accent = Color(0xFFBA1A1A); // Error / Rose Alert Accent
  
  static const Color bgLight = Color(0xFFF8F9FA); // Background Crisp Off-white
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF191C1D); // High contrast text
  static const Color textLight = Color(0xFF454652); // Muted variant text
  static const Color borderLight = Color(0xFFE2E8F0); // Surface Outline (#E2E8F0)

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, Color(0xFF1E1B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        error: accent,
        surface: bgLight,
      ),
      scaffoldBackgroundColor: bgLight,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 0.5rem corner radius
          side: const BorderSide(color: borderLight, width: 1.0), // 1px solid border
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // 0.5rem corner radius
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textLight, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primary, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 0.5rem corner radius
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Premium widgets - Flat design with 1px border and no shadows
  static Widget buildGradientCard({
    required Widget child,
    LinearGradient gradient = primaryGradient,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: primary, // Solid Indigo surface
        borderRadius: BorderRadius.circular(16), // 1rem corner radius for welcome banner
        border: Border.all(color: borderLight.withOpacity(0.5), width: 1.0),
      ),
      child: child,
    );
  }

  // Adaptive Setup View for unconfigured supabase credentials
  static Widget buildSetupScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings_suggest,
                size: 80,
                color: primary,
              ),
              const SizedBox(height: 24),
              const Text(
                "Supabase Belum Dikonfigurasi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Silakan masukkan Supabase URL dan Anon Key Anda di file berikut agar aplikasi dapat terhubung ke database:",
                style: TextStyle(
                  fontSize: 14,
                  color: textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "lib/utils/supabase_config.dart",
                  style: TextStyle(
                    fontFamily: "monospace",
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: const Text("Menunggu Konfigurasi..."),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade700,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Centralized attractive SnackBar notification helper
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    Color bg = backgroundColor ?? primary;
    IconData defaultIcon = icon ?? Icons.info_outline;

    if (backgroundColor == Colors.red || backgroundColor == accent) {
      bg = accent;
      defaultIcon = icon ?? Icons.error_outline;
    } else if (backgroundColor == Colors.green) {
      bg = const Color(0xFF15803D); // Emerald green (Success)
      defaultIcon = icon ?? Icons.check_circle_outline;
    } else if (backgroundColor == Colors.orange) {
      bg = const Color(0xFFC2410C); // Dark orange (Warning)
      defaultIcon = icon ?? Icons.warning_amber_outlined;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(defaultIcon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.0),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
