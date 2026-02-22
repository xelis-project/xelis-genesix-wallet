import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

import 'xswd_relayer.dart';

class XswdPasteConnectionDialog extends ConsumerStatefulWidget {
  const XswdPasteConnectionDialog(this.animation, this.close, {super.key});

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
  bool _hasInput = false;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput == _hasInput && _inputError == null) return;

    setState(() {
      _hasInput = hasInput;
      _inputError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return FDialog(
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
                const Expanded(child: _DialogTitle()),
                FButton.icon(
                  variant: .ghost,
                  onPress: _isProcessing ? null : () => widget.close(),
                  child: const Icon(FIcons.x, size: 22),
                ),
              ],
            ),
          ),
          FTextField(
            control: .managed(controller: _controller),
            label: Text(loc.parameters),
            hint:
                '{"channel_id":"...","relayer":"...","encryption_mode":"aes","encryption_key":"...","app_data":{...}}',
            readOnly: _isProcessing,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            clearable: (controller) {
              return !_isProcessing && controller.text.isNotEmpty;
            },
          ),
          if (_inputError != null) ...[
            const SizedBox(height: Spaces.small),
            Text(
              _inputError!,
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FButton(
              variant: .outline,
              onPress: _isProcessing ? null : () => widget.close(),
              child: Text(loc.cancel_button),
            ),
            const SizedBox(width: Spaces.small),
            FButton(
              onPress: !_isProcessing && _hasInput ? _connectFromPaste : null,
              prefix: _isProcessing
                  ? FInheritedCircularProgressStyle(
                      style: FCircularProgressStyle(
                        iconStyle: IconThemeData(
                          size: 14,
                          color: context.theme.colors.primaryForeground,
                        ),
                      ),
                      child: const FCircularProgress.loader(),
                    )
                  : null,
              child: Text(_isProcessing ? loc.loading : loc.continue_button),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _connectFromPaste() async {
    final loc = ref.read(appLocalizationsProvider);
    final raw = _controller.text
        .replaceAll(RegExp(r'[\r\n\u2028\u2029\u200B\u200C\u200D]'), '')
        .trim();
    if (raw.isEmpty) {
      setState(() {
        _inputError = loc.field_required_error;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _inputError = null;
    });

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
      final waitDeadline = DateTime.now().add(const Duration(seconds: 12));
      while (mounted && ref.read(xswdRequestProvider).decision != null) {
        if (DateTime.now().isAfter(waitDeadline)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      if (!mounted) return;

      widget.close();

      ref
          .read(toastProvider.notifier)
          .showEvent(description: '${loc.connected}: "${relayerData.name}"');
    } catch (e, st) {
      talker.error('XSWD paste processing failed', e, st);

      if (!mounted) return;

      ref.read(toastProvider.notifier).showError(description: e.toString());
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

class _DialogTitle extends ConsumerWidget {
  const _DialogTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Text(
      loc.connection_request,
      style: context.theme.typography.xl2.copyWith(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
