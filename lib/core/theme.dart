import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniWeekTheme {
  // NEW BRAND COLOR
  static const Color primary = Color(0xFF1781B3); // Professional Blue

  // DARK MODE PALETTE
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkText = Colors.white;

  // LIGHT MODE PALETTE (Refined)
  static const Color lightBackground = Color(
    0xFFF3F4F6,
  ); // Light Grey (Contrast for cards)
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1F2937);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      useMaterial3: true,

      // COLOR SCHEME
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: lightSurface,
        onPrimary: Colors.white, // White text on Blue buttons
        onSurface: lightText,
      ),

      // TYPOGRAPHY
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),

      // BUTTONS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white, // Text color
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // FILTER CHIPS (Fixing Visibility)
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: primary,
        disabledColor: Colors.grey.shade200,
        labelStyle: GoogleFonts.outfit(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300), // Visible Border
        ),
      ),

      // CARDS (Adding Pop)
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      // INPUT FIELDS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  // KEEP DARK THEME (Just update primary)
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.apply(bodyColor: darkText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: primary,
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade300),
        secondaryLabelStyle: GoogleFonts.outfit(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
