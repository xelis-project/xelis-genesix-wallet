import 'package:xelis_mobile_wallet/screens/settings/domain/settings_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String translateThemeName(AppLocalizations loc, AppTheme theme) {
  switch (theme) {
    case AppTheme.dark:
      return loc.dark;
    case AppTheme.light:
      return loc.light;
    case AppTheme.xelis:
      return 'XELIS';
  }
}
