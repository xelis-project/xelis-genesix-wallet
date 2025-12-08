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
import 'package:genesix/features/wallet/presentation/address_book/contact_details_screen.dart';
import 'package:genesix/features/wallet/presentation/assets/assets_content.dart';
import 'package:genesix/features/wallet/presentation/history/filters_button.dart';
import 'package:genesix/features/wallet/presentation/history/history_content.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_entry_screen.dart';
import 'package:genesix/features/wallet/presentation/home/home_wallet_content.dart';
import 'package:genesix/features/wallet/presentation/multisig/multisig_content.dart';
import 'package:genesix/features/wallet/presentation/multisig/setup_multisig.dart';
import 'package:genesix/features/wallet/presentation/network/network_content.dart';
import 'package:genesix/features/wallet/presentation/recovery_phrase/recovery_phrase_content.dart';
import 'package:genesix/features/wallet/presentation/sign_transaction/sign_transaction_content.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/burn/burn_screen.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/transfer/transfer_screen.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_content.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_widget_old.dart';
import 'package:genesix/features/wallet/presentation/wallet_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/authentication/presentation/open_wallet_screen.dart';
import 'package:genesix/features/settings/presentation/light_settings_screen.dart';
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
      ImportWalletScreen(),
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
    TypedGoRoute<SignTransactionRoute>(path: '/sign_transaction'),
    TypedGoRoute<MultisigRoute>(path: '/multisig'),
    TypedGoRoute<XSWDRoute>(path: '/xswd'),
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
      AuthAppScreen.history => [const FiltersButton()],
      _ => null,
    };

    final title = switch (authPathScreen) {
      AuthAppScreen.settings => 'Settings',
      AuthAppScreen.network => 'Network',
      AuthAppScreen.addressBook => 'Address Book',
      AuthAppScreen.history => 'History',
      AuthAppScreen.assets => 'Assets',
      AuthAppScreen.recoveryPhrase => 'Recovery Phrase',
      AuthAppScreen.signTransaction => 'Sign Transaction',
      AuthAppScreen.multisig => 'Multisig Management',
      _ => null,
    };

    return pageTransition(
      WalletScaffold(state, navigator, title, suffixes),
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

class SignTransactionRoute extends GoRouteData with _$SignTransactionRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: SignTransactionContent());
  }
}

class MultisigRoute extends GoRouteData with _$MultisigRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: MultisigContent());
  }
}

class XSWDRoute extends GoRouteData with _$XSWDRoute {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(child: XSWDContent());
  }
}

@TypedGoRoute<ContactDetailsRoute>(
  name: 'contact_details',
  path: '/contact_details',
)
class ContactDetailsRoute extends GoRouteData with _$ContactDetailsRoute {
  const ContactDetailsRoute({required this.$extra});

  final String $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      ContactDetailsScreen(contactAddress: $extra),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<TransferRoute>(name: 'transfer', path: '/transfer')
class TransferRoute extends GoRouteData with _$TransferRoute {
  const TransferRoute({this.$extra});

  final String? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      TransferScreen(recipientAddress: $extra),
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
      TransactionEntryScreen(),
      state.pageKey,
      state.fullPath,
      state.extra,
      AppDurations.animNormal,
    );
  }
}

@TypedGoRoute<SetupMultisigRoute>(
  name: 'setup_multisig',
  path: '/setup_multisig',
)
class SetupMultisigRoute extends GoRouteData with _$SetupMultisigRoute {
  const SetupMultisigRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return pageTransition(
      SetupMultisig(),
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
