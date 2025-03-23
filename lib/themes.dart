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
    infoAction: Color(0xFF007AFF),
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
    infoAction: Color(0xFF0A84FF),
    forwardAction: Colors.green,
    folderAction: Color(0xFFCDB4F4),
    quitAction: Color.fromARGB(255, 175, 58, 58),
    cardInfoColor: Colors.teal,
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
    Color? cardInfoAction,
  }) {
    return AppColors(
      deleteAction: deleteAction ?? this.deleteAction,
      saveAction: saveAction ?? this.saveAction,
      warningAction: warningAction ?? this.warningAction,
      infoAction: infoAction ?? this.infoAction,
      forwardAction: forwardAction ?? this.forwardAction,
      folderAction: folderAction ?? this.folderAction,
      quitAction: quitAction ?? this.quitAction,
      cardInfoColor: cardInfoAction ?? this.cardInfoColor,
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
  // macOS light mode color palette
  const primaryBlue = Color(0xFF007AFF);
  const backgroundColor = Color(0xFFF5F5F7);
  const surfaceColor = Color(0xFFFFFFFF);
  const borderColor = Color(0xFFE6E6E6);
  const textColor = Color(0xFF000000);
  const secondaryTextColor = Color(0xFF86868B);

  return ThemeData.light().copyWith(
    colorScheme: ThemeData.light().colorScheme.copyWith(
      secondary: Color(0xFF34C759), // macOS green
      tertiary: backgroundColor,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.only(bottom: 3.0),
      fillColor: Colors.transparent, // This makes the background transparent
      hintStyle: TextStyle(color: Colors.grey), // Add hint text styling
    ),

    // Add text field styling
    // Text theme with defaults preserved
    textTheme: ThemeData.light().textTheme.copyWith(
      // title
      bodyLarge: TextStyle(color: Colors.grey[700]),
      // subtitle
      bodySmall: TextStyle(fontSize: 12, color: Colors.grey[500]),
      // titleSmall is not specified, so it inherits from the default
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}

ThemeData macOSDarkThemeFollow() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Color(0xFF1A222D),

    appBarTheme: AppBarTheme(
      // Remove color as it's deprecated
      elevation: 4.0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18.0),
      backgroundColor: Color(0xFF3D4545), // Use your dark color here
      shadowColor: Colors.black.withValues(
        alpha: 0.7,
      ), // Correct opacity method
      centerTitle: true,
      toolbarHeight: 48, // Reduce height from default ~56 to 48
      titleSpacing: 0, // Reduce spacing around title
    ),

    bottomAppBarTheme: BottomAppBarTheme(
      color: Color(0xFF1A222D),
      elevation: 8.0,
      height: 60.0,
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black54,
    ),

    drawerTheme: DrawerThemeData(backgroundColor: Color(0xFF1A222D)),

    cardTheme: CardTheme(
      color: Color.fromARGB(255, 70, 78, 90),
      elevation: 2.0,
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    colorScheme: ThemeData.dark().colorScheme.copyWith(
      secondary: Color(0xFF34C759), // macOS green
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      isDense: true,
      contentPadding: EdgeInsets.only(bottom: 3.0),
      fillColor: Colors.transparent, // This makes the background transparent
      hintStyle: TextStyle(color: Colors.white60), // Add hint text styling
    ),

    // Add text field styling
    // Text theme with defaults preserved
    textTheme: ThemeData.dark().textTheme.copyWith(
      // title
      bodyLarge: TextStyle(color: Colors.white70),
      // subtitle
      bodySmall: TextStyle(fontSize: 12, color: Colors.white60),
      // titleSmall is not specified, so it inherits from the default
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.dark],
  );
}

/// macOS light mode theme
/// total redesigned
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
      background: backgroundColor,
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
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),

    // Switches, checkboxes, etc.
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.white;
        return const Color(0xFFD8D8D8);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryBlue;
        return const Color(0xFFE9E9EA);
      }),
    ),

    // Customized Extensions
    extensions: <ThemeExtension<dynamic>>[AppColors.light],
  );
}

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
