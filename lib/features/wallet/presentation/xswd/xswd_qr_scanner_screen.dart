import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget_old.dart';
import 'package:genesix/shared/providers/toast_provider.dart';

import 'xswd_relayer.dart';

class XswdQRScannerScreen extends ConsumerStatefulWidget {
  const XswdQRScannerScreen({super.key});

  @override
  ConsumerState<XswdQRScannerScreen> createState() =>
      _XswdQRScannerScreenState();
}

class _XswdQRScannerScreenState extends ConsumerState<XswdQRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.scan_qr_code),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onDetect,
                  ),

                  // Scanner frame
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Instructions
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
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Text(
                        loc.point_camera_at_qr,
                        style: context.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Processing overlay
                  if (_isProcessing)
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: Spaces.medium),
                            Text(
                              'Connecting…',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final raw = (capture.barcodes.first.rawValue ?? "")
      .replaceAll(RegExp(r'[\r\n\u2028\u2029\u200B\u200C\u200D]'), '')
      .trim();
    if (raw == null) return;

    talker.info('=== XSWD QR SCANNED ===');
    talker.info(raw);

    setState(() => _isProcessing = true);
    _processPayload(raw);
  }

  Future<void> _processPayload(String raw) async {
    final loc = ref.read(appLocalizationsProvider);

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = RelaySessionData.fromJson(json);

      final relayerData = session.toApplicationDataRelayer();

      await ref.read(walletStateProvider.notifier).addXswdRelayer(relayerData);

      // Wait for all XSWD permission dialogs to fully complete
      while (mounted && ref.read(xswdRequestProvider).decision != null) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ref.read(toastProvider.notifier).showEvent(
        description: 'Connected to "${relayerData.name}" via relay',
      );
    } catch (e, st) {
      talker.error('XSWD QR processing failed', e, st);

      if (!mounted) return;

      ref.read(toastProvider.notifier).showError(
        description: e.toString(),
      );

      setState(() => _isProcessing = false);
    }
  }
}
