import 'package:flutter/material.dart';

import 'package:xelis_mobile_wallet/shared/colors/color_schemes.g.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class ThemeProvider {
  final ColorScheme lightColors = lightColorScheme;
  final ColorScheme darkColors = darkColorScheme;

  final pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  ShapeBorder get shapeMedium => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      );

  CardTheme cardTheme(ColorScheme colors) {
    return CardTheme(
      elevation: 0,
      color: colors.surfaceVariant,
      // shadowColor: colors.shadow,
      shape: shapeMedium,
      clipBehavior: Clip.antiAlias,
    );
  }

  ListTileThemeData listTileTheme(ColorScheme colors) {
    return ListTileThemeData(
      shape: shapeMedium,
      selectedColor: colors.secondary,
    );
  }

  AppBarTheme appBarTheme(ColorScheme colors) {
    return AppBarTheme(
      elevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
    );
  }

  TabBarTheme tabBarTheme(ColorScheme colors) {
    return TabBarTheme(
      labelColor: colors.secondary,
      unselectedLabelColor: colors.onSurfaceVariant,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.secondary,
            width: 2,
          ),
        ),
      ),
    );
  }

  BottomAppBarTheme bottomAppBarTheme(ColorScheme colors) {
    return BottomAppBarTheme(
      color: colors.surface,
      elevation: 0,
    );
  }

  BottomNavigationBarThemeData bottomNavigationBarTheme(ColorScheme colors) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.surfaceVariant,
      selectedItemColor: colors.onSurface,
      unselectedItemColor: colors.onSurfaceVariant,
      elevation: 0,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    );
  }

  NavigationRailThemeData navigationRailTheme(ColorScheme colors) {
    return const NavigationRailThemeData();
  }

  DrawerThemeData drawerTheme(ColorScheme colors) {
    return DrawerThemeData(
      backgroundColor: colors.surface,
    );
  }

  /*IconButtonThemeData iconTheme(ColorScheme colors) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.onSecondaryContainer,
        backgroundColor: colors.secondaryContainer,
        disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
        hoverColor: colors.onSecondaryContainer.withOpacity(0.08),
        focusColor: colors.onSecondaryContainer.withOpacity(0.12),
        highlightColor: colors.onSecondaryContainer.withOpacity(0.12),
      ),
        // style: IconButton.styleFrom(
        //   focusColor: colors.onSurfaceVariant.withOpacity(0.12),
        //   highlightColor: colors.onSurface.withOpacity(0.12),
        //   side: BorderSide(color: colors.outline),
        // ).copyWith(
        //   foregroundColor: MaterialStateProperty.resolveWith(
        //           (Set<MaterialState> states) {
        //         if (states.contains(MaterialState.pressed)) {
        //           return colors.onSurface;
        //         }
        //         return null;
        //       }),
        // ),
    );
  }*/

  ThemeData light(BuildContext context) {
    return ThemeData.light().copyWith(
      textTheme: context.textTheme,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: lightColors,
      appBarTheme: appBarTheme(lightColors),
      cardTheme: cardTheme(lightColors),
      listTileTheme: listTileTheme(lightColors),
      bottomAppBarTheme: bottomAppBarTheme(lightColors),
      bottomNavigationBarTheme: bottomNavigationBarTheme(lightColors),
      navigationRailTheme: navigationRailTheme(lightColors),
      tabBarTheme: tabBarTheme(lightColors),
      drawerTheme: drawerTheme(lightColors),
      scaffoldBackgroundColor: lightColors.background,
      // iconButtonTheme: iconTheme(lightColors),
      useMaterial3: true,
    );
  }

  ThemeData dark(BuildContext context) {
    return ThemeData.dark().copyWith(
      textTheme: context.textTheme,
      pageTransitionsTheme: pageTransitionsTheme,
      colorScheme: darkColors,
      appBarTheme: appBarTheme(darkColors),
      cardTheme: cardTheme(darkColors),
      listTileTheme: listTileTheme(darkColors),
      bottomAppBarTheme: bottomAppBarTheme(darkColors),
      bottomNavigationBarTheme: bottomNavigationBarTheme(darkColors),
      navigationRailTheme: navigationRailTheme(darkColors),
      tabBarTheme: tabBarTheme(darkColors),
      drawerTheme: drawerTheme(darkColors),
      scaffoldBackgroundColor: darkColors.background,
      // iconButtonTheme: iconTheme(darkColors),
      useMaterial3: true,
    );
  }
}
