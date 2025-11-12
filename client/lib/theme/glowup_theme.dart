import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlowUpColors {
  static const Color mist = Color(0xFFF3F6FB);
  static const Color breeze = Color(0xFF0F4C81);
  static const Color bloom = Color(0xFFFF7A45);
  static const Color dusk = Color(0xFF0A2336);
  static const Color lavender = Color(0xFF4A8FE7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD4DEEB);
  static const Color success = Color(0xFF46A35F);

  static const Color primary = breeze; // default navigation tone
  static const Color secondary = bloom; // warm accent for students
  static const Color accent = lavender; // playful accent for gallery
  static const Color sunset = Color(0xFFFF6B6B);
  static const Color peach = Color(0xFFFFC078);
  static const Color mint = Color(0xFF35C39F);
  static const Color sage = Color(0xFF1FBF8F);
  static const Color midnight = Color(0xFF051523);
  static const Color ivory = Color(0xFFFEFBF4);
  static const Color cobalt = Color(0xFF163D76);
  static const Color amber = Color(0xFFFF9F1C);
  static const Color sky = Color(0xFF56C0FF);
  static const Color plum = Color(0xFF7443FF);
}

class GlowUpTheme {
  static ThemeData lightTheme({bool highContrast = false}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );
    final primary =
        highContrast ? GlowUpColors.midnight : GlowUpColors.primary;
    final secondary =
        highContrast ? GlowUpColors.sunset : GlowUpColors.secondary;
    final cardColor = highContrast ? Colors.white : GlowUpColors.card;
    final background = highContrast ? GlowUpColors.ivory : GlowUpColors.mist;
    final textColor = highContrast ? Colors.black87 : GlowUpColors.dusk;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: cardColor,
      onSurface: textColor,
      background: background,
      onBackground: textColor,
      outline: GlowUpColors.outline,
      brightness: Brightness.light,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 54,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.45,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashColor: GlowUpColors.primary.withValues(alpha: 0.08),
      focusColor: GlowUpColors.primary.withValues(alpha: 0.15),
      hoverColor: GlowUpColors.primary.withValues(alpha: 0.08),
      highlightColor: GlowUpColors.primary.withValues(alpha: 0.04),
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: GlowUpColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontSize: 30,
          color: Colors.white,
        ),
        toolbarTextStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: GlowUpColors.primary.withValues(alpha: 0.15),
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelLarge?.copyWith(letterSpacing: 0.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GlowUpColors.sunset,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GlowUpColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GlowUpColors.primary,
          side: const BorderSide(color: GlowUpColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: GlowUpColors.primary.withValues(alpha: 0.1),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: GlowUpColors.midnight.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GlowUpColors.midnight,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GlowUpColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyLarge,
      ),
      dividerTheme: DividerThemeData(
        color: GlowUpColors.outline,
        thickness: 1,
        space: 32,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: GlowUpColors.midnight,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: cardColor,
        selectedColor: GlowUpColors.primary,
        textColor: textColor,
        iconColor: GlowUpColors.dusk,
      ),
    );
  }
}
