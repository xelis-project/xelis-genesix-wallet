import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:genesix/features/authentication/presentation/create_wallet_screen.dart';
import 'package:genesix/features/authentication/presentation/import_wallet_screen.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/presentation/components/theme_mode_switcher.dart';
import 'package:genesix/features/settings/presentation/settings_content.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_header_action.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_book_content.dart';
import 'package:genesix/features/wallet/presentation/assets/assets_content.dart';
import 'package:genesix/features/wallet/presentation/history/history_content.dart';
import 'package:genesix/features/wallet/presentation/home/home_wallet_content.dart';
import 'package:genesix/features/wallet/presentation/network/network_content.dart';
import 'package:genesix/features/wallet/presentation/recovery_phrase/recovery_phrase_content.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/xswd_status_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/burn/burn_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/multisig/multisig_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transfer/transfer_screen.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/authentication/presentation/open_wallet_screen.dart';
import 'package:genesix/features/settings/presentation/light_settings_screen.dart';
import 'package:genesix/features/wallet/presentation/history_navigation_bar/components/transaction_entry_screen.dart';
import 'package:genesix/shared/theme/constants.dart';

part 'routes.g.dart';

@TypedGoRoute<OpenWalletRoute>(
  path: '/',
  routes: [
    TypedGoRoute<CreateWalletRoute>(path: 'create_wallet'),
    TypedGoRoute<ImportWalletRoute>(path: 'import_wallet'),
    TypedGoRoute<LightSettingsRoute>(path: 'light_settings'),
  ],
)
class OpenWalletRoute extends GoRouteData with _$OpenWalletRoute {
  const OpenWalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const OpenWalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

class CreateWalletRoute extends GoRouteData with _$CreateWalletRoute {
  const CreateWalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const CreateWalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

class ImportWalletRoute extends GoRouteData with _$ImportWalletRoute {
  const ImportWalletRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const ImportWalletScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

class LightSettingsRoute extends GoRouteData with _$LightSettingsRoute {
  const LightSettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const LightSettingsScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedShellRoute<WalletShellRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),
    TypedGoRoute<SettingsContentRoute>(path: '/settings'),
    TypedGoRoute<NetworkRoute>(path: '/network'),
    TypedGoRoute<AddressBookRoute>(path: '/address_book'),
    TypedGoRoute<HistoryRoute>(path: '/history'),
    TypedGoRoute<AssetsRoute>(path: '/assets'),
    TypedGoRoute<RecoveryPhraseRoute>(path: '/recovery_phrase'),
  ],
)
class WalletShellRoute extends ShellRouteData {
  @override
  Page<Function> pageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget navigator,
  ) {
    final authPathScreen = AuthAppScreenExtension.fromPath(state.fullPath!);
    final suffixes = switch (authPathScreen) {
      AuthAppScreen.settings => [const ThemeModeSwitcher()],
      AuthAppScreen.addressBook => [const AddContactHeaderAction()],
      _ => null,
    };

    final title = switch (authPathScreen) {
      AuthAppScreen.settings => 'Settings',
      AuthAppScreen.network => 'Network',
      AuthAppScreen.addressBook => 'Address Book',
      AuthAppScreen.history => 'History',
      AuthAppScreen.assets => 'Assets',
      AuthAppScreen.recoveryPhrase => 'Recovery Phrase',
      _ => null,
    };

    return pageTransition(
      WalletScaffold(navigator, title, suffixes),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

class HomeRoute extends GoRouteData with _$HomeRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: HomeWalletContent());
  }
}

class NetworkRoute extends GoRouteData with _$NetworkRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: NetworkContent());
  }
}

class SettingsContentRoute extends GoRouteData with _$SettingsContentRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: SettingsContent());
  }
}

class AddressBookRoute extends GoRouteData with _$AddressBookRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: AddressBookContent());
  }
}

class AssetsRoute extends GoRouteData with _$AssetsRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: AssetsContent());
  }
}

class HistoryRoute extends GoRouteData with _$HistoryRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: HistoryContent());
  }
}

class RecoveryPhraseRoute extends GoRouteData with _$RecoveryPhraseRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: RecoveryPhraseContent());
  }
}

@TypedGoRoute<TransferRoute>(name: 'transfer', path: '/transfer')
class TransferRoute extends GoRouteData with _$TransferRoute {
  const TransferRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const TransferScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<BurnRoute>(name: 'burn', path: '/burn')
class BurnRoute extends GoRouteData with _$BurnRoute {
  const BurnRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const BurnScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<TransactionEntryRoute>(
  name: 'transaction_entry',
  path: '/transaction_entry',
)
class TransactionEntryRoute extends GoRouteData with _$TransactionEntryRoute {
  const TransactionEntryRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      TransactionEntryScreen(routerState: state),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<MultiSigRoute>(name: 'multisig', path: '/multisig')
class MultiSigRoute extends GoRouteData with _$MultiSigRoute {
  const MultiSigRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const MultisigScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<XswdStateRoute>(name: 'xswd_status', path: '/xswd_status')
class XswdStateRoute extends GoRouteData with _$XswdStateRoute {
  const XswdStateRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      const XswdStatusScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

// This is the function to animate the transition between pages.
CustomTransitionPage<T> pageTransition<T>(
  Widget child,
  ValueKey<String> pageKey,
  String? path,
  Object? arguments,
  int milliDuration,
) => CustomTransitionPage<T>(
  key: pageKey,
  name: path,
  child: child,
  arguments: arguments,
  transitionDuration: Duration(milliseconds: milliDuration),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      // The XswdWidget must be added to the widget tree here to ensure the correct context is available to display the dialog
      // TODO rework this to avoid adding the XswdWidget here
      child: XswdWidget(child),
    );
  },
);

// TODO: Remove this function if not needed.
CustomTransitionPage<T> scaffoldContentTransition<T>(
  Widget child,
  ValueKey<String> pageKey,
  // String? path,
  // Object? arguments,
  int milliDuration,
) => CustomTransitionPage<T>(
  child: child,
  key: pageKey,
  // name: path,
  // child: child,
  // arguments: arguments,
  transitionDuration: Duration(milliseconds: milliDuration),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child,
    );
  },
);
