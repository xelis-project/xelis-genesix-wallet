import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme() {
  const textColor = Colors.black87;
  final lineHeight = 1.2;
  // const primaryColor = Color.fromARGB(255, 34, 34, 34);
  const primaryColor = Color.fromARGB(255, 122, 250, 211);
  const secondaryColor = Color.fromARGB(255, 122, 203, 250);
  const backgroundColor = Color.fromARGB(255, 221, 221, 221);
  final borderRadius = BorderRadius.circular(10.0);

  WidgetStateProperty<Color> switchStateProperty =
      WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return primaryColor;
    }
    return textColor.withValues(alpha: 0.6);
  });

  final baseTheme = ThemeData(
    useMaterial3: true,
    // splashFactory: InkSplash.splashFactory,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: Colors.transparent,

    // COLORS
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor.withValues(alpha: 0.8),
      onPrimary: Colors.black87,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: backgroundColor,
      onSurface: textColor,
    ),

    // EXTENSIONS
    extensions: <ThemeExtension<dynamic>>[
      MoreColors(
        bgRadialColor1: const Color.fromARGB(255, 200, 200, 200),
        bgRadialColor2: const Color.fromARGB(178, 225, 225, 225),
        bgRadialColor3: const Color.fromARGB(130, 150, 150, 150),
        bgRadialEndColor: const Color.fromARGB(0, 255, 255, 255),
        mutedColor: textColor.withValues(alpha: 0.6),
      )
    ],

    // TEXT
    textTheme: TextTheme(
      bodyLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      bodySmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      displayLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      labelLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w700),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: textColor,
      selectionColor: textColor.withValues(alpha: 0.1),
    ),

    // CARD
    cardTheme: CardTheme(
      color: Colors.white12,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        // side: const BorderSide(color: Colors.black12, width: 1),
      ),
    ),

    // BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black12,
        //foregroundColor: primaryColor,
        side: const BorderSide(
            color: Color.fromARGB(255, 122, 250, 211), width: 2),
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        iconColor: Colors.black87,
        disabledBackgroundColor: Colors.black12,
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: Colors.black87),
    ),

    // APP BAR
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),

    // NAVIGATION BAR
    navigationBarTheme: NavigationBarThemeData(
      indicatorShape: CircleBorder(
        side: BorderSide.none,
      ),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.black26,
      indicatorColor: Colors.white,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.jura(color: Colors.white),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.black12,
      selectedItemColor: primaryColor,
      type: BottomNavigationBarType.fixed,
      unselectedItemColor: Colors.black45,
      selectedLabelStyle:
          GoogleFonts.jura(fontSize: 12, fontWeight: FontWeight.w700),
      selectedIconTheme: IconThemeData(size: 36),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.black12,
      indicatorColor: Colors.transparent,
      //useIndicator: false,
      selectedLabelTextStyle: GoogleFonts.jura(
          color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: GoogleFonts.jura(
          color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w700),
      selectedIconTheme: IconThemeData(size: 36, color: primaryColor),
      unselectedIconTheme: IconThemeData(size: 30, color: Colors.black45),
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.black54),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      contentPadding: const EdgeInsets.all(15),
      filled: true,
      fillColor: Colors.black26,
      iconColor: Colors.black26,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.transparent, width: 0),
      ),
      errorMaxLines: 2,
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 2.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
      ),
    ),

    // SNACKBAR
    snackBarTheme: SnackBarThemeData(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),

    // DIALOG
    dialogTheme: DialogTheme(
      backgroundColor: backgroundColor.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      barrierColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      actionsPadding: const EdgeInsets.all(Spaces.medium),
    ),

    // SWITCH
    switchTheme: SwitchThemeData(
      thumbColor: switchStateProperty,
      trackColor: WidgetStatePropertyAll(primaryColor.withValues(alpha: 0.2)),
      trackOutlineColor: switchStateProperty,
    ),

    // TAB BAR
    tabBarTheme: const TabBarTheme(
      dividerColor: Colors.black38,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),

    // MODAL BOTTOM SHEET
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: backgroundColor.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    ),

    // MISC
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      textStyle: const TextStyle(color: textColor),
    ),

    dividerTheme: const DividerThemeData(
      thickness: 2,
      color: Colors.black38,
      space: 20,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.all(10),
      dense: true,
      tileColor: Colors.transparent,
    ),

    sliderTheme: SliderThemeData(
      inactiveTrackColor: Colors.white38,
      trackHeight: 2,
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.juraTextTheme(baseTheme.textTheme),
  );
}
