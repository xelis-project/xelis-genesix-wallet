import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

/// Application strings plus the Material/Cupertino delegates used by Forui.
const genesixLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...FLocalizations.localizationsDelegates,
];
