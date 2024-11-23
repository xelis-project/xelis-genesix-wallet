import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkTheme() {
  const textColor = Colors.white;
  var lineHeight = 1.2;
  // const primaryColor = Color.fromARGB(255, 216, 216, 216);
  const primaryColor = Color.fromARGB(255, 122, 250, 211);
  const secondaryColor = Color.fromARGB(255, 122, 203, 250);
  const backgroundColor = Color.fromARGB(255, 19, 19, 19);
  final borderRadius = BorderRadius.circular(10.0);

  WidgetStateProperty<Color> switchStateProperty =
      WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return primaryColor;
    }
    return textColor.withOpacity(0.6);
  });

  final baseTheme = ThemeData(
    useMaterial3: true,
    // splashFactory: InkSparkle.splashFactory,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: Colors.transparent,

    // COLORS
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
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
        bgRadialColor1: const Color.fromARGB(255, 75, 75, 75),
        bgRadialColor2: const Color.fromARGB(178, 100, 100, 100),
        bgRadialColor3: const Color.fromARGB(153, 25, 25, 25),
        bgRadialEndColor: const Color.fromARGB(0, 0, 0, 0),
        mutedColor: textColor.withOpacity(0.6),
      )
    ],

    // TEXT
    textTheme: TextTheme(
      bodyLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      displayLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      displayMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(
          color: textColor, height: lineHeight, fontWeight: FontWeight.w600),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: textColor,
      selectionColor: textColor.withOpacity(0.1),
    ),

    // CARD
    cardTheme: CardTheme(
      color: Colors.black12,
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
        disabledBackgroundColor: Colors.black87,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
      ),
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
      backgroundColor: Colors.black26,
      selectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle:
          GoogleFonts.jura(fontSize: 12, fontWeight: FontWeight.w600),
      selectedIconTheme: IconThemeData(size: 36),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.black26,
      indicatorColor: Colors.transparent,
      //useIndicator: false,
      selectedLabelTextStyle: GoogleFonts.jura(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: GoogleFonts.jura(
          color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
      selectedIconTheme: IconThemeData(size: 36, color: Colors.white),
      unselectedIconTheme: IconThemeData(size: 30, color: Colors.white54),
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.white54),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      contentPadding: const EdgeInsets.all(15),
      filled: true,
      fillColor: Colors.black26,
      iconColor: Colors.white,
      suffixIconColor: Colors.white,
      prefixIconColor: Colors.white,
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
      actionTextColor: Colors.amber,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),

    // DIALOG
    dialogTheme: DialogTheme(
      backgroundColor: backgroundColor.withOpacity(0.9),
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
      trackColor: WidgetStatePropertyAll(primaryColor.withOpacity(.2)),
      trackOutlineColor: switchStateProperty,
    ),

    // TAB BAR
    tabBarTheme: const TabBarTheme(
      dividerColor: Colors.white30,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),

    // MODAL BOTTOM SHEET
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: backgroundColor.withOpacity(0.9),
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
      color: Colors.white30,
      space: 20,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.all(10),
      dense: true,
      tileColor: Colors.transparent,
      //minVerticalPadding: 5,
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.juraTextTheme(baseTheme.textTheme),
  );
}
