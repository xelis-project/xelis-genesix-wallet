import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/shared/providers/toast_provider.dart';

import 'xswd_relayer.dart';

class XswdPasteConnectionDialog extends ConsumerStatefulWidget {
  const XswdPasteConnectionDialog(
    this.style,
    this.animation,
    this.close, {
    super.key,
  });

  final FDialogStyle style;
  final Animation<double> animation;
  final VoidCallback close;

  @override
  ConsumerState<XswdPasteConnectionDialog> createState() =>
      _XswdPasteConnectionDialogState();
}

class _XswdPasteConnectionDialogState
    extends ConsumerState<XswdPasteConnectionDialog> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: widget.style,
      animation: widget.animation,
      constraints: const BoxConstraints(maxWidth: 700),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spaces.extraSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Paste connection info',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: _isProcessing ? null : () => widget.close(),
                  child: const Icon(FIcons.x, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.small),
          Text(
            'Paste the JSON payload from the dApp (same content as the QR code).',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.medium),
          TextField(
            controller: _controller,
            enabled: !_isProcessing,
            maxLines: 10,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText:
                  '{"channel_id":"...","relayer":"...","encryption_mode":"aes","encryption_key":"...","app_data":{...}}',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FButton(
              style: FButtonStyle.secondary(),
              onPress: _isProcessing ? null : () => widget.close(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: Spaces.small),
            FButton(
              style: FButtonStyle.primary(),
              onPress: _isProcessing ? null : _connectFromPaste,
              prefix: _isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FIcons.link, size: 18),
              child: Text(_isProcessing ? 'Connecting…' : 'Connect'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _connectFromPaste() async {
    final raw = _controller.text
        .replaceAll(RegExp(r'[\r\n\u2028\u2029\u200B\u200C\u200D]'), '')
        .trim();
    if (raw.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = RelaySessionData.fromJson(json);

      final relayerData = session.toApplicationDataRelayer();

      talker.info('=== XSWD PASTE CONNECT ===');
      talker.info('Relayer WS URL: ${relayerData.relayer}');
      talker.info('App name: ${relayerData.name}');
      talker.info('Permissions: ${relayerData.permissions}');

      await ref.read(walletStateProvider.notifier).addXswdRelayer(relayerData);

      // Wait for all XSWD permission dialogs to fully complete
      while (mounted && ref.read(xswdRequestProvider).decision != null) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      if (!mounted) return;

      widget.close();

      ref
          .read(toastProvider.notifier)
          .showEvent(
            description: 'Connected to "${relayerData.name}" via relay',
          );
    } catch (e, st) {
      talker.error('XSWD paste processing failed', e, st);

      if (!mounted) return;

      setState(() => _isProcessing = false);
    }
  }
}
