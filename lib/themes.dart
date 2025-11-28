import 'package:flutter/material.dart';

// Define your custom theme extension
class AppColors extends ThemeExtension<AppColors> {
  final Color deleteAction;
  final Color saveAction;
  final Color warningAction;
  final Color infoAction;
  final Color forwardAction;
  final Color folderAction;
  final Color quitAction;
  final Color clearAction;
  final Color cardInfoColor;

  const AppColors({
    required this.deleteAction,
    required this.saveAction,
    required this.warningAction,
    required this.infoAction,
    required this.forwardAction,
    required this.folderAction,
    required this.quitAction,
    required this.clearAction,
    required this.cardInfoColor,
  });

  // For light theme - Soft & Elegant
  static const light = AppColors(
    deleteAction: Color(0xFFEF5350), // Soft Red
    saveAction: Color(0xFF66BB6A), // Soft Green
    warningAction: Color(0xFFFFA726), // Soft Orange
    infoAction: Color(0xFF29B6F6), // Soft Light Blue
    forwardAction: Color(0xFF66BB6A),
    folderAction: Color(0xFF7E57C2), // Soft Deep Purple
    quitAction: Color(0xFFD32F2F),
    clearAction: Color(0xFFE3F2FD),
    cardInfoColor: Color(0xFFE3F2FD), // Very light blue
  );

  // For dark theme - Soft & Elegant
  static const dark = AppColors(
    deleteAction: Color(0xFFE57373),
    saveAction: Color(0xFF81C784),
    warningAction: Color(0xFFFFB74D),
    infoAction: Color(0xFF4FC3F7),
    forwardAction: Color(0xFF81C784),
    folderAction: Color(0xFF9575CD),
    quitAction: Color(0xFFEF5350),
    clearAction: Color(0xFF263238),
    cardInfoColor: Color(0xFF263238), // Dark Blue Grey
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? deleteAction,
    Color? saveAction,
    Color? warningAction,
    Color? infoAction,
    Color? forwardAction,
    Color? folderAction,
    Color? quitAction,
    Color? clearAction,
    Color? cardInfoColor,
  }) {
    return AppColors(
      deleteAction: deleteAction ?? this.deleteAction,
      saveAction: saveAction ?? this.saveAction,
      warningAction: warningAction ?? this.warningAction,
      infoAction: infoAction ?? this.infoAction,
      forwardAction: forwardAction ?? this.forwardAction,
      folderAction: folderAction ?? this.folderAction,
      quitAction: quitAction ?? this.quitAction,
      clearAction: clearAction ?? this.clearAction,
      cardInfoColor: cardInfoColor ?? this.cardInfoColor,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      deleteAction: Color.lerp(deleteAction, other.deleteAction, t)!,
      saveAction: Color.lerp(saveAction, other.saveAction, t)!,
      warningAction: Color.lerp(warningAction, other.warningAction, t)!,
      infoAction: Color.lerp(infoAction, other.infoAction, t)!,
      forwardAction: Color.lerp(forwardAction, other.forwardAction, t)!,
      folderAction: Color.lerp(folderAction, other.folderAction, t)!,
      quitAction: Color.lerp(quitAction, other.quitAction, t)!,
      clearAction: Color.lerp(clearAction, other.clearAction, t)!,
      cardInfoColor: Color.lerp(cardInfoColor, other.cardInfoColor, t)!,
    );
  }
}

/// Soft & Elegant Light Theme
ThemeData macOSLightThemeFollow() {
  // Soft & Elegant Palette
  const primaryColor = Color(0xFF5C6BC0); // Indigo 400
  const secondaryColor = Color(0xFF26A69A); // Teal 400
  const backgroundColor = Color(0xFFF5F7FA); // Blue Grey 50
  const surfaceColor = Colors.white;
  const errorColor = Color(0xFFEF5350); // Red 400

  // Typography Colors
  const titleColor = Color(0xFF37474F); // Blue Grey 800
  const bodyColor = Color(0xFF546E7A); // Blue Grey 600
  const labelColor = Color(0xFF78909C); // Blue Grey 400

  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,

    colorScheme: ThemeData.light().colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      surfaceContainerHighest: const Color(0xFFECEFF1), // Blue Grey 50
    ),

    // Enhanced AppBar - Clean & Minimal
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: backgroundColor, // Blend with background
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: titleColor, size: 22),
      actionsIconTheme: IconThemeData(color: titleColor, size: 22),
      titleTextStyle: TextStyle(
        color: titleColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // Soft Card Design
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0, // Flat design with border or very subtle shadow
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // More rounded
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
    ),

    // Enhanced Bottom App Bar
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: surfaceColor,
      elevation: 0,
      height: 70.0,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      surfaceTintColor: Colors.transparent,
      shape: AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    ),

    // Modern Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      width: 280,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Soft Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0, // Flat
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields - Soft & Airy
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: labelColor),
      errorStyle: TextStyle(fontSize: 12, color: errorColor),
    ),

    // Enhanced text theme
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: bodyColor, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: bodyColor, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: labelColor),
    ),

    // Icon theme
    iconTheme: IconThemeData(size: 24, color: bodyColor),

    // Divider
    dividerTheme: DividerThemeData(
      color: Colors.black.withValues(alpha: 0.06),
      thickness: 1,
      space: 1,
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}

/// Soft & Elegant Dark Theme
ThemeData macOSDarkThemeFollow() {
  // Soft & Elegant Dark Palette
  const primaryColor = Color(0xFF7986CB); // Indigo 300
  const secondaryColor = Color(0xFF4DB6AC); // Teal 300
  const backgroundColor = Color(0xFF1A1B1E); // Soft Dark Grey
  const surfaceColor = Color(0xFF2C2E33); // Lighter Dark Grey
  const errorColor = Color(0xFFE57373); // Red 300

  // Typography Colors
  const titleColor = Color(0xFFECEFF1); // Blue Grey 50
  const bodyColor = Color(0xFFB0BEC5); // Blue Grey 200
  const labelColor = Color(0xFF78909C); // Blue Grey 400

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,

    colorScheme: ThemeData.dark().colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      surfaceContainerHighest: const Color(0xFF37474F),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: titleColor, size: 22),
      actionsIconTheme: IconThemeData(color: titleColor, size: 22),
      titleTextStyle: TextStyle(
        color: titleColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    bottomAppBarTheme: BottomAppBarThemeData(
      color: surfaceColor,
      elevation: 0,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      surfaceTintColor: Colors.transparent,
      shape: const AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      width: 280,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: const Color(0xFF1A1B1E),
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: const Color(0xFF1A1B1E),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF25282C), // Slightly darker than surface
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: labelColor),
      errorStyle: TextStyle(fontSize: 12, color: errorColor),
    ),

    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: bodyColor, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: bodyColor, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: labelColor),
    ),

    iconTheme: IconThemeData(size: 24, color: bodyColor),

    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      thickness: 1,
      space: 1,
    ),

    extensions: <ThemeExtension<dynamic>>[AppColors.dark],
  );
}

/// macOS light mode theme
/// total redesigned
/*
ThemeData macOSLightTheme() {
  // macOS light mode color palette
  const primaryBlue = Color(0xFF007AFF);
  const backgroundColor = Color(0xFFF5F5F7);
  const surfaceColor = Color(0xFFFFFFFF);
  const borderColor = Color(0xFFE6E6E6);
  const textColor = Color(0xFF000000);
  const secondaryTextColor = Color(0xFF86868B);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: Color(0xFF34C759), // macOS green
      surface: surfaceColor,
      error: Color(0xFFFF3B30), // macOS red
    ),

    // Typography
    fontFamily: '.AppleSystemUIFont', // Try to use system font
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      ),
    ),

    // Component themes
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),

    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderColor),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: primaryBlue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),

    // Dividers and separators
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),

    // Dialogs and popovers
    // dialogTheme: DialogTheme(
    //   backgroundColor: surfaceColor,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //   elevation: 0,
    // ),

    // Switches, checkboxes, etc.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFD8D8D8);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryBlue;
        return const Color(0xFFE9E9EA);
      }),
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}
*/

ThemeData macOSDarkTheme() {
  // macOS color palette
  const primaryBlue = Color(0xFF0A84FF);
  const backgroundDark = Color(0xFF1E1E1E);
  const surfaceDark = Color(0xFF2D2D2D);
  const elevatedSurfaceDark = Color(0xFF3A3A3A);

  return ThemeData.dark().copyWith(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundDark,
    cardColor: surfaceDark,
    canvasColor: surfaceDark,

    // App bar with macOS styling
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: false, // macOS typically has left-aligned titles
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: elevatedSurfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryBlue, width: 1),
      ),
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.dark],
  );
}
