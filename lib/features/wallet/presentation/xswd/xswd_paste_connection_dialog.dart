import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

import 'xswd_relayer.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';

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
  bool _hasHandedOff = false;
  String? _inputError;
  String? _pendingRelayerAppId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    ref.listenManual<XswdRequestState>(
      xswdRequestProvider,
      _onXswdRequestChanged,
    );
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

  void _onXswdRequestChanged(
    XswdRequestState? previous,
    XswdRequestState next,
  ) {
    if (!_isProcessing ||
        _hasHandedOff ||
        _pendingRelayerAppId == null ||
        next.decision == null ||
        previous?.decision == next.decision ||
        next.xswdEventSummary?.applicationInfo.id != _pendingRelayerAppId) {
      return;
    }

    if (_closeDialogIfCurrent()) {
      // The relay may reuse the local server's callbacks. Open from the
      // matching input handoff so both handler paths behave the same way.
      ref.read(xswdRequestProvider.notifier).requestOpenDialog();
    }
  }

  bool _closeDialogIfCurrent() {
    if (_hasHandedOff || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }

    _hasHandedOff = true;
    widget.close();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AppDialog(
      clipBehavior: Clip.antiAlias,
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
                  child: const Icon(FLucideIcons.x, size: 22),
                ),
              ],
            ),
          ),
          FTextField(
            control: .managed(controller: _controller),
            label: Text(loc.parameters),
            hint:
                '{"relayer":"...","encryption_mode":{mode, key},"app_data":{...}}',
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
              style: context.theme.typography.body.sm.copyWith(
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

    late final ApplicationDataRelayer relayerData;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      relayerData = RelaySessionData.fromJson(json).toApplicationDataRelayer();
    } catch (error) {
      talker.error('XSWD paste payload parsing failed (${error.runtimeType})');

      if (!mounted) return;

      ref
          .read(toastProvider.notifier)
          .showError(description: loc.invalid_connection_data);
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    _pendingRelayerAppId = relayerData.id;
    final toastNotifier = ref.read(toastProvider.notifier);
    try {
      final connected = await ref
          .read(xswdControllerProvider)
          .addXswdRelayer(relayerData);
      if (!connected) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _pendingRelayerAppId = null;
        });
        return;
      }

      if (!_hasHandedOff) {
        if (mounted) {
          _closeDialogIfCurrent();
        }
        toastNotifier.showEvent(
          description: loc.app_connected_title(relayerData.name),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _pendingRelayerAppId = null;
        });
      }
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
      style: context.theme.typography.display.xl2,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
