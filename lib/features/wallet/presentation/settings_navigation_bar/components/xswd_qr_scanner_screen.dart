import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget_old.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

/// Data structure for relayed XSWD connection QR codes
class RelayerQRData {
  final String channelId;
  final String relayer;
  final String encryptionMode;
  final String? encryptionKey;
  final Map<String, dynamic>? appData;

  RelayerQRData({
    required this.channelId,
    required this.relayer,
    required this.encryptionMode,
    this.encryptionKey,
    this.appData,
  });

  factory RelayerQRData.fromJson(Map<String, dynamic> json) {
    return RelayerQRData(
      channelId: json['channel_id'] as String,
      relayer: json['relayer'] as String,
      encryptionMode: json['encryption_mode'] as String,
      encryptionKey: json['encryption_key'] as String?,
      appData: json['app_data'] as Map<String, dynamic>?,
    );
  }
}

class XswdQRScannerScreen extends ConsumerStatefulWidget {
  const XswdQRScannerScreen({super.key});

  @override
  ConsumerState<XswdQRScannerScreen> createState() =>
      _XswdQRScannerScreenState();
}

class _XswdQRScannerScreenState extends ConsumerState<XswdQRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
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
      appBar: GenericAppBar(title: 'Scan QR Code'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Camera preview
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onDetect,
                  ),
                  // Scanning frame overlay
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Overlay with instructions
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
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Text(
                        'Point your camera at the QR code displayed in the dApp',
                        style: context.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Processing indicator
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
                              'Connecting...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    talker.info('=== QR CODE SCANNED ===');
    talker.info('Raw data: $code');

    setState(() {
      _isProcessing = true;
    });

    _processQRCode(code);
  }

  Future<void> _processQRCode(String code) async {
    try {
      // Parse JSON
      final data = jsonDecode(code) as Map<String, dynamic>;
      talker.info('Parsed JSON: $data');

      final qrData = RelayerQRData.fromJson(data);
      talker.info('Channel ID: ${qrData.channelId}');
      talker.info('Relayer: ${qrData.relayer}');
      talker.info('Encryption mode: ${qrData.encryptionMode}');
      talker.info('App data: ${qrData.appData}');

      // Validate required fields
      if (qrData.channelId.isEmpty || qrData.relayer.isEmpty) {
        throw Exception('Invalid QR code: missing required fields');
      }

      // Decode encryption key from base64
      EncryptionMode? encryptionMode;
      if (qrData.encryptionKey != null && qrData.encryptionKey!.isNotEmpty) {
        final keyBytes = Uint8List.fromList(base64Decode(qrData.encryptionKey!));
        talker.info('Encryption key length: ${keyBytes.length} bytes');
        if (keyBytes.length != 32) {
          throw Exception('Invalid encryption key length: expected 32 bytes');
        }

        if (qrData.encryptionMode == 'aes') {
          encryptionMode = EncryptionMode.aes(key: keyBytes);
        } else if (qrData.encryptionMode == 'chacha20poly1305') {
          encryptionMode = EncryptionMode.chacha20Poly1305(key: keyBytes);
        } else {
          throw Exception('Unsupported encryption mode: ${qrData.encryptionMode}');
        }
      }

      // Extract app data from QR code
      if (qrData.appData == null) {
        throw Exception('QR code missing app_data');
      }

      final appData = qrData.appData!;
      final appId = appData['id'] as String;
      final appName = appData['name'] as String;
      final appDescription = appData['description'] as String? ?? '';
      final appUrl = appData['url'] as String?;
      final permissions = (appData['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [];

      // Construct relayer WebSocket URL with channel ID
      final relayerUrl = '${qrData.relayer}/ws/${qrData.channelId}';
      talker.info('Constructed relayer URL: $relayerUrl');

      talker.info('Received real app data from dApp:');
      talker.info('App ID: $appId');
      talker.info('App name: $appName');
      talker.info('App description: $appDescription');
      talker.info('App URL: $appUrl');
      talker.info('Permissions: $permissions');

      // Create ApplicationDataRelayer with real app data
      final relayerData = ApplicationDataRelayer(
        id: appId,
        name: appName,
        description: appDescription,
        url: appUrl,
        permissions: permissions,
        relayer: relayerUrl,
        encryptionMode: encryptionMode,
      );

      talker.info('Created ApplicationDataRelayer with real app data');

      // Connect to relay
      talker.info('Calling addXswdRelayer...');
      await ref.read(walletStateProvider.notifier).addXswdRelayer(relayerData);
      talker.info('addXswdRelayer completed successfully');

      if (mounted) {
        // Success - close scanner and show success message
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to "$appName" via relay'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      talker.error('ERROR processing QR code: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
