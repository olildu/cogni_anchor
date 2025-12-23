import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color primary = Color(0xFFFF653A);
  static const Color primaryDark = Color(0xFFE04F25);
  static const Color primaryLight = Color(0xFFFFE5DE); 

  static const Color background = Color(0xFFFAFAFA); 
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1A1C1E); 
  static const Color textSecondary = Color(0xFF6C757D); 
  static const Color textLight = Colors.white;

  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF4757);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleMedium: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          textStyle:
              GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        hintStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 14.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      ),
    );
  }
}
