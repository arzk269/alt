import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF475569);
  static const inkFaint = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  static const blue = Color(0xFF1E40AF);
  static const blueSoft = Color(0xFFEFF6FF);

  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFFFBEB);

  static const green = Color(0xFF047857);
  static const greenSoft = Color(0xFFECFDF5);

  static const brick = Color(0xFF9A3412);
  static const brickSoft = Color(0xFFFFF7ED);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue, primary: AppColors.blue),
  textTheme: GoogleFonts.ibmPlexSansTextTheme(),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  ),
);

TextStyle monoStyle({double size = 12, FontWeight weight = FontWeight.w500, Color color = AppColors.inkFaint}) {
  return GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);
}
