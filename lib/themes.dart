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

  // For light theme - Vibrant & Clean
  static const light = AppColors(
    deleteAction: Color(0xFFF43F5E), // Modern Rose
    saveAction: Color(0xFF10B981), // Modern Emerald
    warningAction: Color(0xFFF59E0B), // Modern Amber
    infoAction: Color(0xFF0EA5E9), // Modern Sky Blue
    forwardAction: Color(0xFF10B981), // Modern Emerald
    folderAction: Color(0xFF6366F1), // Modern Indigo
    quitAction: Color(0xFFE11D48),
    clearAction: Color(0xFFF1F5F9),
    cardInfoColor: Color(0xFFF8FAFC),
  );

  // For dark theme - Sleek OLED & Neon Accents
  static const dark = AppColors(
    deleteAction: Color(0xFFFB7185), // Soft Neon Rose
    saveAction: Color(0xFF34D399), // Soft Neon Emerald
    warningAction: Color(0xFFFBBF24), // Soft Neon Amber
    infoAction: Color(0xFF38BDF8), // Soft Neon Sky
    forwardAction: Color(0xFF34D399),
    folderAction: Color(0xFF818CF8), // Soft Neon Indigo
    quitAction: Color(0xFFF43F5E),
    clearAction: Color(0xFF1E293B),
    cardInfoColor: Color(0xFF1E222A),
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

/// Modern & Elegant Light Theme
ThemeData macOSLightThemeFollow() {
  const primaryColor = Color(0xFF4F46E5); // Modern Indigo
  const secondaryColor = Color(0xFF10B981); // Emerald
  const backgroundColor = Color(0xFFF8FAFC); // Slate 50
  const surfaceColor = Colors.white;
  const errorColor = Color(0xFFEF4444); // Red 500

  // Typography Colors
  const titleColor = Color(0xFF0F172A); // Slate 900
  const bodyColor = Color(0xFF334155); // Slate 700
  const labelColor = Color(0xFF64748B); // Slate 500

  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,

    colorScheme: ThemeData.light().colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: titleColor, size: 22),
      actionsIconTheme: IconThemeData(color: titleColor, size: 22),
      titleTextStyle: TextStyle(
        color: titleColor,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: surfaceColor,
      elevation: 0,
      height: 68.0,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      surfaceTintColor: Colors.transparent,
      shape: AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      width: 320,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: labelColor),
      errorStyle: const TextStyle(fontSize: 12, color: errorColor),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: bodyColor, height: 1.45),
      bodyMedium: TextStyle(fontSize: 13.5, color: bodyColor, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, color: labelColor),
    ),

    iconTheme: const IconThemeData(size: 22, color: bodyColor),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),

    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}

/// Modern & Elegant Dark Theme
ThemeData macOSDarkThemeFollow() {
  const primaryColor = Color(0xFF6366F1); // Indigo 500
  const secondaryColor = Color(0xFF34D399); // Emerald 400
  const backgroundColor = Color(0xFF0F172A); // Slate 900
  const surfaceColor = Color(0xFF1E293B); // Slate 800
  const errorColor = Color(0xFFF87171); // Red 400

  // Typography Colors
  const titleColor = Color(0xFFF8FAFC); // Slate 50
  const bodyColor = Color(0xFFCBD5E1); // Slate 300
  const labelColor = Color(0xFF94A3B8); // Slate 400

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,

    colorScheme: ThemeData.dark().colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      surfaceContainerHighest: const Color(0xFF334155),
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: titleColor, size: 22),
      actionsIconTheme: IconThemeData(color: titleColor, size: 22),
      titleTextStyle: TextStyle(
        color: titleColor,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: surfaceColor,
      elevation: 0,
      height: 68.0,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      surfaceTintColor: Colors.transparent,
      shape: AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      width: 320,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: Color(0xFF475569)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: labelColor),
      errorStyle: const TextStyle(fontSize: 12, color: errorColor),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: titleColor,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: bodyColor, height: 1.45),
      bodyMedium: TextStyle(fontSize: 13.5, color: bodyColor, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, color: labelColor),
    ),

    iconTheme: const IconThemeData(size: 22, color: bodyColor),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
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
