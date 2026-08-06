import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

/// Returns safe, localized copy for a structured application failure.
String appFailureDescription(
  AppLocalizations localizations,
  AppFailure failure,
) => switch (failure.category) {
  AppFailureCategory.invalidInput => localizations.wallet_failure_invalid_input,
  AppFailureCategory.authenticationOrCorruptData =>
    localizations.wallet_failure_authentication_or_corrupt_data,
  AppFailureCategory.offline => localizations.action_not_available_offline,
  AppFailureCategory.networkFailure => localizations.wallet_failure_network,
  AppFailureCategory.operationInProgress =>
    localizations.wallet_failure_network,
  AppFailureCategory.networkMismatch => localizations.network_mismatch,
  AppFailureCategory.daemonRejected =>
    localizations.wallet_failure_daemon_rejected,
  AppFailureCategory.insufficientFunds =>
    localizations.wallet_failure_insufficient_funds,
  _ => localizations.wallet_failure_generic,
};
