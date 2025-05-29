import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

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
