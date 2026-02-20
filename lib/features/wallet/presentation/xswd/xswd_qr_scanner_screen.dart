import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

import 'xswd_relayer.dart';

class XswdQRScannerScreen extends ConsumerStatefulWidget {
  const XswdQRScannerScreen({super.key});

  @override
  ConsumerState<XswdQRScannerScreen> createState() =>
      _XswdQRScannerScreenState();
}

class _XswdQRScannerScreenState extends ConsumerState<XswdQRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    autoZoom: true,
    detectionTimeoutMs: 300,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final scanner = LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = _frameSize(constraints.biggest);
        final scanWindow = Rect.fromCenter(
          center: constraints.biggest.center(Offset.zero),
          width: frameSize,
          height: frameSize,
        );

        return Stack(
          children: [
            MobileScanner(
              controller: _cameraController,
              scanWindow: scanWindow,
              onDetect: _onDetect,
              onDetectError: _onDetectError,
              placeholderBuilder: (context) =>
                  const Center(child: FCircularProgress()),
              errorBuilder: (context, error) => _ScannerErrorView(
                message: _scannerMessage(error),
                onRetry: _restartScanner,
              ),
            ),
            _ScannerOverlay(
              frameSize: frameSize,
              instruction: loc.point_camera_at_qr,
            ),
            if (_isProcessing) _ProcessingOverlay(label: loc.loading),
          ],
        );
      },
    );

    return FScaffold(
      header: FHeader.nested(
        title: Text(loc.scan_qr_code),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.x(
              onPress: _isProcessing ? null : () => context.pop(),
            ),
          ),
        ],
        suffixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: _TorchAction(
              cameraController: _cameraController,
              disabled: _isProcessing,
              onToggle: _toggleTorch,
            ),
          ),
        ],
      ),
      child: SafeArea(top: false, child: scanner),
    );
  }

  double _frameSize(Size viewport) {
    final shortest = viewport.shortestSide;
    return (shortest * 0.62).clamp(180.0, 320.0);
  }

  String _scannerMessage(MobileScannerException error) {
    final detail = error.errorDetails?.message?.trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    return error.errorCode.message;
  }

  void _onDetectError(Object error, StackTrace stackTrace) {
    talker.error('XSWD barcode detect stream error', error, stackTrace);
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
    } catch (e, st) {
      talker.error('XSWD torch toggle failed', e, st);
    }
  }

  Future<void> _restartScanner() async {
    try {
      await _cameraController.start();
    } catch (e, st) {
      talker.error('XSWD scanner restart failed', e, st);
      if (!mounted) return;
      ref.read(toastProvider.notifier).showError(description: e.toString());
    }
  }

  void _pauseScanner() {
    unawaited(
      _cameraController.stop().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        talker.error('XSWD scanner pause failed', error, stackTrace);
      }),
    );
  }

  void _resumeScanner() {
    unawaited(
      _cameraController.start().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        talker.error('XSWD scanner resume failed', error, stackTrace);
      }),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final raw = (capture.barcodes.first.rawValue ?? '')
        .replaceAll(RegExp(r'[\r\n\u2028\u2029\u200B\u200C\u200D]'), '')
        .trim();
    if (raw.isEmpty) return;

    talker.info('=== XSWD QR SCANNED ===');
    talker.info(raw);

    setState(() => _isProcessing = true);
    _pauseScanner();
    _processPayload(raw);
  }

  Future<void> _processPayload(String raw) async {
    final loc = ref.read(appLocalizationsProvider);

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = RelaySessionData.fromJson(json);

      final relayerData = session.toApplicationDataRelayer();

      await ref.read(walletStateProvider.notifier).addXswdRelayer(relayerData);

      // Wait for all XSWD permission dialogs to fully complete.
      final waitDeadline = DateTime.now().add(const Duration(seconds: 12));
      while (mounted && ref.read(xswdRequestProvider).decision != null) {
        if (DateTime.now().isAfter(waitDeadline)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      if (!mounted) return;

      context.pop();

      ref
          .read(toastProvider.notifier)
          .showEvent(description: '${loc.connected}: "${relayerData.name}"');
    } catch (e, st) {
      talker.error('XSWD QR processing failed', e, st);

      if (!mounted) return;

      ref.read(toastProvider.notifier).showError(description: e.toString());
      setState(() {
        _isProcessing = false;
      });
      _resumeScanner();
    }
  }
}

class _TorchAction extends StatelessWidget {
  const _TorchAction({
    required this.cameraController,
    required this.disabled,
    required this.onToggle,
  });

  final MobileScannerController cameraController;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: cameraController,
      builder: (context, state, child) {
        if (state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }

        final torchOn = state.torchState == TorchState.on;
        return FTooltip(
          tipBuilder: (context, controller) =>
              Text(torchOn ? 'Turn flashlight off' : 'Turn flashlight on'),
          child: FHeaderAction(
            icon: Icon(torchOn ? FIcons.flashlightOff : FIcons.flashlight),
            onPress: disabled ? null : onToggle,
          ),
        );
      },
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.frameSize, required this.instruction});

  final double frameSize;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Center(
            child: Container(
              width: frameSize,
              height: frameSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 2.2,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(Spaces.large),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Text(
                instruction,
                style: context.theme.typography.base.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FInheritedCircularProgressStyle(
                style: FCircularProgressStyle(
                  iconStyle: IconThemeData(size: 20, color: Colors.white),
                ),
                child: const FCircularProgress.loader(),
              ),
              const SizedBox(height: Spaces.medium),
              Text(
                label,
                style: context.theme.typography.base.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(Spaces.large),
          child: FCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FIcons.triangleAlert, size: 22, color: muted),
                const SizedBox(height: Spaces.small),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.sm.copyWith(color: muted),
                ),
                const SizedBox(height: Spaces.medium),
                SizedBox(
                  width: 180,
                  child: FButton(
                    style: FButtonStyle.outline(),
                    onPress: onRetry,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
