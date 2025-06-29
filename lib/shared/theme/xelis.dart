import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData xelisTheme() {
  const textColor = Colors.white;
  var lineHeight = 1.2;
  const primaryColor = Color.fromARGB(255, 122, 250, 211);
  const secondaryColor = Color.fromARGB(255, 122, 203, 250);
  const backgroundColor = Color.fromARGB(255, 19, 19, 19);
  final borderRadius = BorderRadius.circular(10.0);

  WidgetStateProperty<Color> switchStateProperty =
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return textColor.withValues(alpha: 0.6);
      });

  WidgetStateBorderSide chipBorderStateProperty =
      WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BorderSide(color: primaryColor, width: 2);
        }
        return BorderSide(color: textColor.withValues(alpha: 0.6), width: 2);
      });

  final baseTheme = ThemeData(
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: Colors.transparent,
    focusColor: Colors.transparent,

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
        bgRadialColor1: const Color.fromARGB(255, 0, 170, 129),
        bgRadialColor2: const Color.fromARGB(178, 5, 124, 132),
        bgRadialColor3: const Color.fromARGB(153, 0, 170, 150),
        bgRadialEndColor: const Color.fromARGB(255, 0, 0, 0),
        mutedColor: textColor.withValues(alpha: 0.6),
      ),
    ],

    // APP BAR
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),

    // TEXT
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      displayLarge: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textColor,
        height: lineHeight,
        fontWeight: FontWeight.w600,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: textColor,
      selectionColor: textColor.withValues(alpha: 0.1),
    ),

    // CARD
    cardTheme: CardThemeData(
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
          color: Color.fromARGB(255, 122, 250, 211),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: Spaces.medium,
          horizontal: Spaces.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        //backgroundColor: primaryColor,
        //foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          vertical: Spaces.medium,
          horizontal: Spaces.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        disabledBackgroundColor: Colors.black87,
        iconColor: Colors.black87,
        disabledIconColor: Colors.white24,
        padding: const EdgeInsets.symmetric(
          vertical: Spaces.medium,
          horizontal: Spaces.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
      ),
    ),

    // NAVIGATION BAR
    navigationBarTheme: NavigationBarThemeData(
      indicatorShape: CircleBorder(side: BorderSide.none),
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
      selectedLabelStyle: GoogleFonts.jura(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedIconTheme: IconThemeData(size: 36),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.black26,
      indicatorColor: Colors.transparent,
      //useIndicator: false,
      selectedLabelTextStyle: GoogleFonts.jura(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.jura(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedIconTheme: const IconThemeData(size: 36, color: Colors.white),
      unselectedIconTheme: const IconThemeData(size: 30, color: Colors.white54),
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
      fillColor: Colors.black45,
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
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    ),

    // DIALOG
    dialogTheme: DialogThemeData(
      backgroundColor: backgroundColor /*.withValues(alpha: 0.9)*/,
      surfaceTintColor: Colors.transparent,
      barrierColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      actionsPadding: const EdgeInsets.all(Spaces.medium),
    ),

    // SWITCH
    switchTheme: SwitchThemeData(
      thumbColor: switchStateProperty,
      trackColor: WidgetStatePropertyAll(primaryColor.withValues(alpha: 0.2)),
      trackOutlineColor: switchStateProperty,
    ),

    // TAB BAR
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.white30,
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
      color: Colors.white30,
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

    chipTheme: ChipThemeData(
      color: WidgetStatePropertyAll(Colors.transparent),
      elevation: 0,
      padding: const EdgeInsets.all(Spaces.small),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      brightness: Brightness.dark,
      side: chipBorderStateProperty,
    ),

    checkboxTheme: CheckboxThemeData(
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.juraTextTheme(baseTheme.textTheme),
  );
}
