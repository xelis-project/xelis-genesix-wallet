import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/xswd_callbacks.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

part 'xswd_controller_provider.g.dart';

@Riverpod(keepAlive: true)
XswdController xswdController(Ref ref) {
  return XswdController(ref);
}

class XswdController {
  const XswdController(this.ref);

  final Ref ref;

  Future<void> sync({
    required bool enabled,
    required bool hasSession,
    required bool isOnline,
  }) async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (!hasSession || !isOnline) {
      _resetXswdUiState();
      await _stopXswdInternal(repository);
      return;
    }

    if (!enabled) {
      _resetXswdUiState();
      await _stopXswdInternal(repository, emitErrors: true);
      return;
    }

    await startXSWD();
  }

  Future<void> startXSWD() async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) {
      return;
    }

    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      talker.info('XSWD skipped: unsupported platform');
      return;
    }

    try {
      final callbacks = buildXswdCallbacks(channelTitle: 'XSWD');
      await repository.startXSWD(
        cancelRequestCallback: callbacks.cancelRequestCallback,
        requestApplicationCallback: callbacks.requestApplicationCallback,
        requestPermissionCallback: callbacks.requestPermissionCallback,
        requestPrefetchPermissionsCallback:
            callbacks.requestPrefetchPermissionsCallback,
        appDisconnectCallback: callbacks.appDisconnectCallback,
      );
      ref.invalidate(xswdApplicationsProvider);
      talker.info('XSWD server started successfully');
    } on AnyhowException catch (error) {
      talker.error('Cannot start XSWD: $error');
      _emitError(
        title: 'Cannot start XSWD',
        description: _extractXelisMessage(error),
      );
    } catch (error) {
      talker.error('Cannot start XSWD: $error');
      _emitError(title: 'Cannot start XSWD', description: error.toString());
    }
  }

  Future<void> stopXSWD() async {
    _resetXswdUiState();
    await _stopXswdInternal(
      ref.read(activeWalletRepositoryProvider),
      emitErrors: true,
    );
  }

  Future<void> closeXswdAppConnection(AppInfo appInfo) async {
    final repository = ref.read(activeWalletRepositoryProvider);
    final loc = ref.read(appLocalizationsProvider);
    if (repository == null) {
      return;
    }

    try {
      await repository.removeXswdApp(appInfo.id);
      ref.invalidate(xswdApplicationsProvider);
      _emitInfo(title: '${appInfo.name} ${loc.disconnected.toLowerCase()}');
    } on AnyhowException catch (error) {
      talker.error('Cannot close XSWD app connection: $error');
      _emitError(
        title: 'Cannot close XSWD app connection',
        description: _extractXelisMessage(error),
      );
    } catch (error) {
      talker.error('Cannot close XSWD app connection: $error');
      _emitError(
        title: 'Cannot close XSWD app connection',
        description: error.toString(),
      );
    }
  }

  Future<void> addXswdRelayer(ApplicationDataRelayer relayerData) async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) {
      return;
    }

    try {
      final callbacks = buildXswdCallbacks(channelTitle: 'XSWD Relayer');
      await repository.addXswdRelayer(
        cancelRequestCallback: callbacks.cancelRequestCallback,
        requestApplicationCallback: callbacks.requestApplicationCallback,
        requestPermissionCallback: callbacks.requestPermissionCallback,
        requestPrefetchPermissionsCallback:
            callbacks.requestPrefetchPermissionsCallback,
        appDisconnectCallback: callbacks.appDisconnectCallback,
        relayerData: relayerData,
      );
      ref.invalidate(xswdApplicationsProvider);
      talker.info('XSWD relay connection added: ${relayerData.name}');
    } on AnyhowException catch (error) {
      talker.error('Cannot add XSWD relay connection: $error');
      _emitError(
        title: 'Cannot add XSWD relay connection',
        description: _extractXelisMessage(error),
      );
      rethrow;
    } catch (error) {
      talker.error('Cannot add XSWD relay connection: $error');
      _emitError(
        title: 'Cannot add XSWD relay connection',
        description: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> editXswdAppPermission(
    String appID,
    Map<String, PermissionPolicy> permissions,
  ) async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) {
      return;
    }

    try {
      await repository.modifyXSWDAppPermissions(appID, permissions);
      ref.invalidate(xswdApplicationsProvider);
    } on AnyhowException catch (error) {
      talker.error('Cannot edit XSWD app permission: $error');
      _emitError(
        title: 'Cannot edit XSWD app permission',
        description: _extractXelisMessage(error),
      );
    } catch (error) {
      talker.error('Cannot edit XSWD app permission: $error');
      _emitError(
        title: 'Cannot edit XSWD app permission',
        description: error.toString(),
      );
    }
  }

  XswdCallbacks buildXswdCallbacks({required String channelTitle}) {
    final loc = ref.read(appLocalizationsProvider);

    return XswdCallbacks(
      cancelRequestCallback: (request) async {
        final appName = request.applicationInfo.name;
        final message = '$channelTitle: ${loc.request_cancelled_from} $appName';

        talker.info(message);
        ref
            .read(xswdRequestProvider.notifier)
            .newRequest(xswdEventSummary: request, message: message);

        if (!_isXswdToastSuppressed()) {
          _emitXswd(title: message, showOpen: false);
        }
      },
      requestApplicationCallback: (request) {
        final appName = request.applicationInfo.name;
        final message =
            '$channelTitle: ${loc.connection_request_from} $appName';
        return _askXswdUserPermission(
          request: request,
          message: message,
          showOpen: true,
        );
      },
      requestPermissionCallback: (request) {
        final appName = request.applicationInfo.name;
        final message =
            '$channelTitle: ${loc.permission_request_from} $appName';
        return _askXswdUserPermission(
          request: request,
          message: message,
          showOpen: true,
        );
      },
      requestPrefetchPermissionsCallback: (request) {
        final appName = request.applicationInfo.name;
        final message =
            '$channelTitle: ${loc.prefetch_permissions_request_from} $appName';
        return _askXswdUserPermission(
          request: request,
          message: message,
          showOpen: true,
        );
      },
      appDisconnectCallback: (request) async {
        final appName = request.applicationInfo.name;
        final message =
            '$channelTitle: $appName ${loc.disconnected.toLowerCase()}';

        talker.info(message);
        ref
            .read(xswdRequestProvider.notifier)
            .newRequest(xswdEventSummary: request, message: message);

        if (!_isXswdToastSuppressed()) {
          _emitXswd(title: message, showOpen: false);
        }
      },
    );
  }

  bool _isXswdToastSuppressed() {
    return ref.read(xswdRequestProvider).suppressXswdToast;
  }

  Future<UserPermissionDecision> _askXswdUserPermission({
    required XswdRequestSummary request,
    required String message,
    required bool showOpen,
  }) async {
    talker.info(message);

    final decision = ref
        .read(xswdRequestProvider.notifier)
        .newRequest(xswdEventSummary: request, message: message);

    if (!_isXswdToastSuppressed()) {
      _emitXswd(title: message, showOpen: showOpen);
    }

    return decision.future;
  }

  Future<void> _stopXswdInternal(
    NativeWalletRepository? repository, {
    bool emitErrors = false,
  }) async {
    if (repository == null) {
      ref.invalidate(xswdApplicationsProvider);
      return;
    }

    try {
      await repository.stopXSWD();
      talker.info('XSWD server stop initiated');
      ref.invalidate(xswdApplicationsProvider);
    } on AnyhowException catch (error) {
      if (emitErrors) {
        talker.error('Cannot stop XSWD: $error');
        _emitError(
          title: 'Cannot stop XSWD',
          description: _extractXelisMessage(error),
        );
      }
    } catch (error) {
      if (emitErrors) {
        talker.error('Cannot stop XSWD: $error');
        _emitError(title: 'Cannot stop XSWD', description: error.toString());
      }
    }
  }

  void _resetXswdUiState() {
    ref.read(xswdRequestProvider.notifier).clearRequest();
    ref.invalidate(xswdApplicationsProvider);
  }

  void _emitInfo({required String title}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.info(title: title));
  }

  void _emitError({String? title, required String description}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.error(title: title, description: description));
  }

  void _emitXswd({
    required String title,
    String? description,
    required bool showOpen,
  }) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(
          WalletEffect.xswd(
            title: title,
            description: description,
            showOpen: showOpen,
          ),
        );
  }

  String _extractXelisMessage(AnyhowException error) {
    return error.message.split('\n').first;
  }
}
