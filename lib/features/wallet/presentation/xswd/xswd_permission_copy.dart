import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

String? xswdPermissionImpact(XswdMethodEffect effect, AppLocalizations loc) =>
    switch (effect) {
      XswdMethodEffect.publicInformation => loc.xswd_permission_public_impact,
      XswdMethodEffect.walletData => loc.xswd_permission_wallet_data_impact,
      XswdMethodEffect.appStorage => loc.xswd_permission_app_storage_impact,
      // Transactions have their dedicated review; unsupported methods never
      // reach the generic permission approval surface.
      XswdMethodEffect.transaction ||
      XswdMethodEffect.walletControl ||
      XswdMethodEffect.decryption ||
      XswdMethodEffect.signing ||
      XswdMethodEffect.proof => null,
    };
