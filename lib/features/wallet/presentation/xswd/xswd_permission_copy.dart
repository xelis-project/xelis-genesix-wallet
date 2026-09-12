import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

final class XswdPermissionCopy {
  const XswdPermissionCopy({required this.title, required this.description});

  final String title;
  final String description;
}

XswdPermissionCopy xswdPermissionCopy(
  String method,
  XswdMethodPolicy? policy,
  AppLocalizations loc,
) {
  final description = switch (method) {
    'get_version' => loc.xswd_public_read_description(
      loc.xswd_method_wallet_version_title,
    ),
    'get_address' => loc.xswd_method_get_address_description,
    'get_balance' => loc.xswd_method_get_balance_description,
    'get_asset' => loc.xswd_method_get_asset_description,
    'get_assets' => loc.xswd_method_get_assets_description,
    'network_info' => loc.xswd_method_network_info_description,
    'get_network' => loc.xswd_public_read_description(loc.network),
    'get_topoheight' => loc.xswd_public_read_description(loc.topoheight),
    'split_address' => loc.xswd_public_read_description(
      loc.xswd_method_split_address_title,
    ),
    'get_asset_precision' => loc.xswd_public_read_description(
      loc.xswd_method_asset_precision_title,
    ),
    'is_online' => loc.xswd_public_read_description(loc.online_mode),
    'estimate_fees' => loc.xswd_public_calculate_description(loc.fee),
    'estimate_extra_data_size' => loc.xswd_public_calculate_description(
      loc.xswd_method_attached_data_size_title,
    ),
    'verify_signed_data' => loc.xswd_public_verify_description(
      loc.xswd_method_signed_data_title,
    ),
    'verify_human_readable_proof' => loc.xswd_public_verify_description(
      loc.xswd_method_human_readable_proof_title,
    ),
    'get_nonce' => loc.xswd_wallet_read_description(
      loc.xswd_method_nonce_title,
    ),
    'has_balance' => loc.xswd_wallet_read_description(
      loc.xswd_method_check_balance_title,
    ),
    'get_tracked_assets' => loc.xswd_wallet_read_description(
      loc.xswd_method_tracked_assets_title,
    ),
    'get_transaction' => loc.xswd_wallet_read_description(
      loc.xswd_method_transaction_details_title,
    ),
    'dump_transaction' => loc.xswd_wallet_read_description(
      loc.xswd_method_transaction_dump_title,
    ),
    'search_transaction' => loc.xswd_wallet_read_description(
      loc.xswd_method_transaction_search_title,
    ),
    'list_transactions' => loc.xswd_wallet_read_description(
      loc.xswd_method_transaction_history_title,
    ),
    'get_pending_transactions' => loc.xswd_wallet_read_description(
      loc.xswd_method_pending_transactions_title,
    ),
    'is_asset_tracked' => loc.xswd_wallet_read_description(
      loc.xswd_method_asset_tracking_status_title,
    ),
    _ =>
      policy == null || !policy.isSupported
          ? loc.xswd_permission_unsupported_impact
          : xswdPermissionImpact(policy.effect, loc),
  };

  final title = switch (method) {
    'get_address' => loc.address,
    'get_balance' => loc.balance,
    'get_asset' => loc.asset,
    'get_assets' => loc.assets,
    'network_info' => loc.xswd_method_network_info_title,
    'get_version' => loc.xswd_method_wallet_version_title,
    'get_network' => loc.network,
    'get_topoheight' => loc.topoheight,
    'split_address' => loc.xswd_method_split_address_title,
    'get_asset_precision' => loc.xswd_method_asset_precision_title,
    'is_online' => loc.online_mode,
    'estimate_fees' => loc.fee,
    'estimate_extra_data_size' => loc.xswd_method_attached_data_size_title,
    'verify_signed_data' => loc.xswd_method_signed_data_title,
    'verify_human_readable_proof' => loc.xswd_method_human_readable_proof_title,
    'get_nonce' => loc.xswd_method_nonce_title,
    'has_balance' => loc.xswd_method_check_balance_title,
    'get_tracked_assets' => loc.xswd_method_tracked_assets_title,
    'get_transaction' => loc.xswd_method_transaction_details_title,
    'dump_transaction' => loc.xswd_method_transaction_dump_title,
    'search_transaction' => loc.xswd_method_transaction_search_title,
    'list_transactions' => loc.xswd_method_transaction_history_title,
    'get_pending_transactions' => loc.xswd_method_pending_transactions_title,
    'is_asset_tracked' => loc.xswd_method_asset_tracking_status_title,
    'get_matching_keys' => loc.xswd_method_matching_storage_keys_title,
    'count_matching_entries' => loc.xswd_method_count_storage_entries_title,
    'get_value_from_key' => loc.xswd_method_read_storage_value_title,
    'store' => loc.xswd_method_store_value_title,
    'delete' => loc.xswd_method_delete_value_title,
    'delete_tree_entries' => loc.xswd_method_clear_storage_tree_title,
    'has_key' => loc.xswd_method_check_storage_key_title,
    'query_db' => loc.xswd_method_query_storage_title,
    'subscribe' => loc.xswd_permission_subscribe_title,
    'unsubscribe' => loc.xswd_permission_unsubscribe_title,
    'build_transaction' => loc.xswd_permission_transaction_title,
    'build_transaction_offline' =>
      loc.xswd_method_build_offline_transaction_title,
    'build_unsigned_transaction' =>
      loc.xswd_method_build_unsigned_transaction_title,
    'finalize_unsigned_transaction' =>
      loc.xswd_method_finalize_unsigned_transaction_title,
    'sign_unsigned_transaction' => loc.sign_transaction,
    'sign_data' => loc.xswd_method_sign_data_title,
    'rescan' => loc.rescan,
    'clear_tx_cache' => loc.xswd_method_clear_transaction_cache_title,
    'set_online_mode' => loc.connect_node,
    'set_offline_mode' => loc.xswd_method_disconnect_node_title,
    'track_asset' => loc.xswd_method_track_asset_title,
    'untrack_asset' => loc.untrack,
    'decrypt_extra_data' => loc.xswd_method_decrypt_extra_data_title,
    'decrypt_ciphertext' => loc.xswd_method_decrypt_ciphertext_title,
    'create_ownership_proof' => loc.xswd_method_create_ownership_proof_title,
    'create_balance_proof' => loc.xswd_method_create_balance_proof_title,
    _ when policy == null || !policy.isSupported =>
      loc.xswd_permission_unsupported_title,
    _ => switch (policy.effect) {
      XswdMethodEffect.publicInformation => loc.xswd_permission_public_title,
      XswdMethodEffect.walletData => loc.xswd_permission_wallet_data_title,
      XswdMethodEffect.appStorage => loc.xswd_permission_app_storage_title,
      XswdMethodEffect.walletSubscription =>
        loc.xswd_permission_subscribe_title,
      XswdMethodEffect.walletUnsubscription =>
        loc.xswd_permission_unsubscribe_title,
      XswdMethodEffect.transaction => loc.xswd_permission_transaction_title,
      XswdMethodEffect.walletControl ||
      XswdMethodEffect.decryption ||
      XswdMethodEffect.signing ||
      XswdMethodEffect.proof => loc.xswd_permission_unsupported_title,
    },
  };

  return XswdPermissionCopy(title: title, description: description);
}

String xswdPermissionImpact(XswdMethodEffect effect, AppLocalizations loc) =>
    switch (effect) {
      XswdMethodEffect.publicInformation => loc.xswd_permission_public_impact,
      XswdMethodEffect.walletData => loc.xswd_permission_wallet_data_impact,
      XswdMethodEffect.appStorage => loc.xswd_permission_app_storage_impact,
      XswdMethodEffect.walletSubscription =>
        loc.xswd_permission_subscription_impact,
      XswdMethodEffect.walletUnsubscription =>
        loc.xswd_permission_unsubscription_impact,
      XswdMethodEffect.transaction => loc.xswd_transaction_review_warning,
      XswdMethodEffect.walletControl ||
      XswdMethodEffect.decryption ||
      XswdMethodEffect.signing ||
      XswdMethodEffect.proof => loc.xswd_permission_unsupported_impact,
    };

String xswdWalletEventLabel(WalletEvent event, AppLocalizations loc) =>
    switch (event) {
      WalletEvent.newTopoheight => loc.xswd_event_new_topoheight,
      WalletEvent.newAsset => loc.xswd_event_new_asset,
      WalletEvent.newTransaction => loc.xswd_event_new_transaction,
      WalletEvent.balanceChanged => loc.xswd_event_balance_changed,
      WalletEvent.rescan => loc.xswd_event_rescan,
      WalletEvent.online => loc.xswd_event_online,
      WalletEvent.offline => loc.xswd_event_offline,
      WalletEvent.historySynced => loc.xswd_event_history_synced,
      WalletEvent.syncError => loc.xswd_event_sync_error,
      WalletEvent.trackAsset => loc.xswd_event_track_asset,
      WalletEvent.untrackAsset => loc.xswd_event_untrack_asset,
      WalletEvent.newPendingTransaction =>
        loc.xswd_event_new_pending_transaction,
    };
