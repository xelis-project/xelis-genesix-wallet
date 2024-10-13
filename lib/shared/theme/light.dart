import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme() {
  const textColor = Colors.black;
  var lineHeight = 1.2;
  const primaryColor = Color.fromARGB(255, 34, 34, 34);
  const secondaryColor = Color.fromARGB(255, 122, 203, 250);
  const backgroundColor = Color.fromARGB(255, 221, 221, 221);
  var borderRadius = BorderRadius.circular(10.0);

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
    // TODO deactivated until we find a better combo color/shape
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,

    // COLORS
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
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
      color: Colors.white12,
      shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: Colors.black12, width: 1)),
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
        //backgroundColor: primaryColor,
        //foregroundColor: Colors.black,
        //textStyle: TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
            vertical: Spaces.medium, horizontal: Spaces.medium),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.w800),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
          //backgroundColor: primaryColor,
          //foregroundColor: Colors.black87,
          //shape: const CircleBorder(
          //  side: BorderSide(color: Colors.transparent),
          //),
          //highlightColor: primaryColor.darken(10),
          //focusColor: primaryColor.lighten(15),
          //hoverColor: primaryColor.lighten(15),
          ),
    ),

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
      backgroundColor: Colors.black12,
      selectedItemColor: primaryColor,
      type: BottomNavigationBarType.fixed,
      unselectedItemColor: Colors.black45,
      selectedLabelStyle:
          GoogleFonts.jura(fontSize: 12, fontWeight: FontWeight.w600),
      selectedIconTheme: IconThemeData(size: 36),
      //showUnselectedLabels: false,
      //showSelectedLabels: false,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.black12,
      indicatorColor: Colors.transparent,
      //useIndicator: false,
      selectedLabelTextStyle: GoogleFonts.jura(
          color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: GoogleFonts.jura(
          color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
      selectedIconTheme: IconThemeData(size: 36, color: primaryColor),
      unselectedIconTheme: IconThemeData(size: 30, color: Colors.black45),
      /*indicatorShape: CircleBorder(
        side: BorderSide(color: Colors.transparent,width: 0),
      ),*/
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.black54),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      contentPadding: const EdgeInsets.all(15),
      filled: true,
      fillColor: Colors.black26,
      iconColor: Colors.black26,
      suffixIconColor: primaryColor,
      prefixIconColor: primaryColor,
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
      // actionTextColor: Colors.amber,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),

    // DIALOG
    dialogTheme: DialogTheme(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      //actionsPadding: EdgeInsets.all(10)
    ),

    // SWITCH
    switchTheme: SwitchThemeData(
      thumbColor: switchStateProperty,
      trackColor: WidgetStatePropertyAll(primaryColor.withOpacity(.2)),
      trackOutlineColor: switchStateProperty,
    ),

    // TAB BAR
    tabBarTheme: const TabBarTheme(
      dividerColor: Colors.black38,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
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
        iconColor: primaryColor
        //minVerticalPadding: 5,
        ),

    expansionTileTheme: const ExpansionTileThemeData(
        collapsedIconColor: primaryColor, iconColor: primaryColor),
    scaffoldBackgroundColor: Colors.transparent,

    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, foregroundColor: primaryColor),

    radioTheme:
        RadioThemeData(fillColor: WidgetStateProperty.all(primaryColor)),

    dividerColor: Colors.transparent,
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.juraTextTheme(baseTheme.textTheme),
  );
}
