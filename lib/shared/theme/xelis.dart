import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/shared/theme/more_colors.dart';

ThemeData xelisTheme() {
  const textColor = Colors.white;
  const primaryColor = Color.fromARGB(255, 122, 250, 211);
  const secondaryColor = Color.fromARGB(255, 122, 203, 250);
  const backgrounColor = Color.fromARGB(255, 19, 19, 19);
  var borderRadius = BorderRadius.circular(10.0);

  return ThemeData(
    // COLORS
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.black87,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: backgrounColor,
      onBackground: textColor,
      surface: Colors.black,
      onSurface: Colors.white,
    ),

    // EXTENSIONS
    extensions: <ThemeExtension<dynamic>>[
      MoreColors(
        bgRadialColor1: const Color.fromARGB(255, 0, 170, 129),
        bgRadialColor2: const Color.fromARGB(178, 5, 124, 132),
        bgRadialColor3: const Color.fromARGB(153, 0, 170, 150),
        bgRadialEndColor: const Color.fromARGB(255, 0, 0, 0),
        mutedColor: textColor.withOpacity(0.6),
      )
    ],

    // TEXT
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColor),
      displayLarge: TextStyle(color: textColor),
      displayMedium: TextStyle(color: textColor),
      displaySmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor),
      titleSmall: TextStyle(color: textColor),
      labelLarge: TextStyle(color: textColor),
      labelMedium: TextStyle(color: textColor),
      labelSmall: TextStyle(color: textColor),
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
          side: const BorderSide(color: Colors.black12, width: 1)),
    ),

    // BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black12,
        //foregroundColor: primaryColor,
        side: const BorderSide(
            color: Color.fromARGB(255, 122, 250, 211), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
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
    navigationBarTheme: const NavigationBarThemeData(
      indicatorShape: CircleBorder(
        side: BorderSide.none,
      ),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.black26,
      indicatorColor: Colors.white,
      labelTextStyle: MaterialStatePropertyAll(
        TextStyle(
          color: Colors.white,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black12,
      selectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: TextStyle(fontSize: 12),
      selectedIconTheme: IconThemeData(size: 36),
      //showUnselectedLabels: false,
      //showSelectedLabels: false,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.black26,
      indicatorColor: Colors.transparent,
      //useIndicator: false,
      selectedLabelTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      unselectedLabelTextStyle: TextStyle(color: Colors.white54, fontSize: 12),
      selectedIconTheme: IconThemeData(size: 36, color: Colors.white),
      unselectedIconTheme: IconThemeData(size: 30, color: Colors.white54),
      /*indicatorShape: CircleBorder(
        side: BorderSide(color: Colors.transparent,width: 0),
      ),*/
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: Colors.white),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 14,
        fontWeight: FontWeight.bold,
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
    ),

    // SNACKBAR
    snackBarTheme: SnackBarThemeData(
      backgroundColor: backgrounColor,
      actionTextColor: Colors.amber,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),

    // DIALOG
    dialogTheme: DialogTheme(
      backgroundColor: backgrounColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      //actionsPadding: EdgeInsets.all(10)
    ),

    // MISC
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: backgrounColor,
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

    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent
    ),
  );
}
