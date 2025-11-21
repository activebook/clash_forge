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
  final Color cardInfoColor;
  // Add any custom color names you need

  const AppColors({
    required this.deleteAction,
    required this.saveAction,
    required this.warningAction,
    required this.infoAction,
    required this.forwardAction,
    required this.folderAction,
    required this.quitAction,
    required this.cardInfoColor,
  });

  // For light theme
  static const light = AppColors(
    deleteAction: Color(0xFFFF3B30),
    saveAction: Color(0xFF34C759),
    warningAction: Color(0xFFFF9500),
    infoAction: Color(0xFF34C759),
    forwardAction: Colors.green,
    folderAction: Colors.deepPurple,
    quitAction: Color.fromARGB(255, 150, 30, 30),
    cardInfoColor: Color.fromARGB(255, 184, 251, 236),
  );

  // For dark theme
  static const dark = AppColors(
    deleteAction: Color(0xFFFF453A),
    saveAction: Color(0xFF30D158),
    warningAction: Color(0xFFFF9F0A),
    infoAction: Color(0xFF30D158),
    forwardAction: Colors.green,
    folderAction: Color(0xFFCDB4F4),
    quitAction: Color.fromARGB(255, 175, 58, 58),
    cardInfoColor: Color(0xFF1C2128),
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
      cardInfoColor: Color.lerp(cardInfoColor, other.cardInfoColor, t)!,
    );
  }
}

/// inherits from macOS light mode theme
/// only add extensions here
ThemeData macOSLightThemeFollow() {
  // Modern color palette
  const primaryBlue = Color(0xFF0066FF);
  const backgroundColor = Color(0xFFF8F9FA);
  const surfaceColor = Color(0xFFFFFFFF);
  const secondaryGreen = Color(0xFF00C853);

  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: ThemeData.light().colorScheme.copyWith(
      primary: primaryBlue,
      secondary: secondaryGreen,
      tertiary: backgroundColor,
      surface: surfaceColor,
      surfaceContainerHighest: const Color(0xFFF5F5F7),
    ),

    // Enhanced AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      iconTheme: IconThemeData(color: Color(0xFF1F1F1F), size: 22),
      actionsIconTheme: IconThemeData(color: Color(0xFF1F1F1F), size: 22),
      titleTextStyle: TextStyle(
        color: Color(0xFF1F1F1F),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Modern Card Design
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),

    // Enhanced Bottom App Bar
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: surfaceColor,
      elevation: 8.0,
      height: 65.0,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
    ),

    // Modern Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceColor,
      elevation: 16,
      shadowColor: Colors.black26,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),

    // Enhanced Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryBlue.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.only(bottom: 3.0),
      fillColor: Colors.transparent,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
    ),

    // Enhanced text theme
    textTheme: ThemeData.light().textTheme.copyWith(
      titleSmall: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F1F1F),
      ),
      bodyMedium: const TextStyle(fontSize: 15, color: Color(0xFF424242)),
      bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
      bodySmall: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
    ),

    // Icon theme
    iconTheme: const IconThemeData(size: 22, color: Color(0xFF424242)),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}

ThemeData macOSDarkThemeFollow() {
  // Modern dark color palette - GitHub-inspired
  const backgroundDark = Color(0xFF0D1117);
  const surfaceDark = Color(0xFF161B22);
  const elevatedSurfaceDark = Color(0xFF21262D);
  const primaryBlueDark = Color(0xFF58A6FF);
  const secondaryGreenDark = Color(0xFF3FB950);

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundDark,

    colorScheme: ThemeData.dark().colorScheme.copyWith(
      primary: primaryBlueDark,
      secondary: secondaryGreenDark,
      surface: surfaceDark,
      surfaceContainerHighest: elevatedSurfaceDark,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFFC9D1D9), size: 22),
      actionsIconTheme: const IconThemeData(color: Color(0xFFC9D1D9), size: 22),
      titleTextStyle: const TextStyle(
        color: Color(0xFFC9D1D9),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: surfaceDark,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      centerTitle: true,
      toolbarHeight: 56,
      titleSpacing: 0,
    ),

    bottomAppBarTheme: BottomAppBarThemeData(
      color: surfaceDark,
      elevation: 12.0,
      height: 65.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.8),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: surfaceDark,
      elevation: 16,
      shadowColor: Colors.black87,
    ),

    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2.0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: elevatedSurfaceDark.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlueDark,
      foregroundColor: Color(0xFF0D1117),
      elevation: 6,
      highlightElevation: 10,
      shape: CircleBorder(),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlueDark,
        foregroundColor: backgroundDark,
        elevation: 3,
        shadowColor: primaryBlueDark.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      isDense: true,
      contentPadding: EdgeInsets.only(bottom: 3.0),
      fillColor: Colors.transparent,
      hintStyle: TextStyle(color: Color(0xFF8B949E)),
      errorStyle: TextStyle(fontSize: 12, color: Color(0xFFFF7B72)),
    ),

    textTheme: ThemeData.dark().textTheme.copyWith(
      titleSmall: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFFC9D1D9),
      ),
      bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFC9D1D9)),
      bodyMedium: const TextStyle(fontSize: 15, color: Color(0xFF8B949E)),
      bodySmall: const TextStyle(fontSize: 13, color: Color(0xFF6E7681)),
    ),

    iconTheme: const IconThemeData(size: 22, color: Color(0xFF8B949E)),

    dividerTheme: DividerThemeData(
      color: elevatedSurfaceDark.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),

    extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
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
