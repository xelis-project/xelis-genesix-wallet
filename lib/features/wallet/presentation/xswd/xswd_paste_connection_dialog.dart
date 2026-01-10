import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

import 'xswd_relayer.dart';

class XswdPasteConnectionDialog extends ConsumerStatefulWidget {
  const XswdPasteConnectionDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

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
                  onPress: _isProcessing ? null : () => Navigator.of(context).pop(),
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
              onPress: _isProcessing ? null : () => Navigator.of(context).pop(),
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
    final raw = _controller.text.trim();
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

      if (!mounted) return;

      Navigator.of(context).pop(); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to "${relayerData.name}" via relay'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, st) {
      talker.error('XSWD paste processing failed', e, st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isProcessing = false);
    }
  }
}
