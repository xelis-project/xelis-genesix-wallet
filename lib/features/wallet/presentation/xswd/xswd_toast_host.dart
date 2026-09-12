import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

/// Presents the single persistent XSWD approval entry below the app toaster.
class XswdToastHost extends ConsumerStatefulWidget {
  const XswdToastHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<XswdToastHost> createState() => _XswdToastHostState();
}

class _XswdToastHostState extends ConsumerState<XswdToastHost> {
  BuildContext? _toastContext;
  FToasterEntry? _entry;
  _XswdToastEntryControl? _entryControl;
  XswdNotice? _visibleNotice;
  XswdNotice? _queuedNotice;

  @override
  void initState() {
    super.initState();
    ref.listenManual<WalletEffectEnvelope?>(
      walletEffectBusProvider,
      _onWalletEffect,
      fireImmediately: true,
    );
    ref.listenManual(
      xswdRequestProvider,
      _onRequestChanged,
      fireImmediately: true,
    );
    ref.listenManual(
      xswdDialogCoordinatorProvider,
      _onDialogStateChanged,
      fireImmediately: true,
    );
  }

  void _onWalletEffect(
    WalletEffectEnvelope? previous,
    WalletEffectEnvelope? next,
  ) {
    if (next == null || previous?.id == next.id) return;
    switch (next.effect) {
      case WalletXswdEffect(:final notice):
        _queueNotice(notice);
      default:
        break;
    }
  }

  void _onRequestChanged(XswdRequestState? previous, XswdRequestState next) {
    final current = _visibleNotice;
    if (current != null &&
        (!next.pending || !identical(next.token, current.token))) {
      _dismissCurrent();
    }
    _restoreCurrentNoticeIfNeeded();
  }

  void _onDialogStateChanged(XswdDialogState? previous, XswdDialogState next) {
    final current = _visibleNotice;
    if (current != null && identical(next.presentedToken, current.token)) {
      _dismissCurrent();
      return;
    }
    _restoreCurrentNoticeIfNeeded();
  }

  void _restoreCurrentNoticeIfNeeded() {
    if (!mounted || _visibleNotice != null || _queuedNotice != null) return;
    final request = ref.read(xswdRequestProvider);
    if (!request.pending || request.suppressXswdToast) return;
    final token = request.token;
    if (token == null ||
        identical(
          ref.read(xswdDialogCoordinatorProvider).presentedToken,
          token,
        )) {
      return;
    }
    final notice = ref.read(xswdRequestProvider.notifier).currentNotice;
    if (notice != null) _queueNotice(notice);
  }

  void _queueNotice(XswdNotice notice) {
    _queuedNotice = notice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_queuedNotice?.token, notice.token)) return;
      _queuedNotice = null;
      if (!_canPresent(notice)) {
        _restoreCurrentNoticeIfNeeded();
        return;
      }
      final toastContext = _toastContext;
      if (toastContext == null) {
        _queueNotice(notice);
        return;
      }
      _showNotice(toastContext, notice);
    });
  }

  bool _canPresent(XswdNotice notice) {
    final request = ref.read(xswdRequestProvider);
    return request.pending &&
        !request.suppressXswdToast &&
        identical(request.token, notice.token) &&
        !identical(
          ref.read(xswdDialogCoordinatorProvider).presentedToken,
          notice.token,
        ) &&
        ref.read(xswdRequestProvider.notifier).isCurrent(notice.token);
  }

  void _showNotice(BuildContext toastContext, XswdNotice notice) {
    _dismissCurrent();
    final style = _toastStyle(toastContext);
    final control = _XswdToastEntryControl();
    _visibleNotice = notice;
    _entryControl = control;
    _entry = showRawFToast(
      context: toastContext,
      style: style,
      duration: null,
      swipeToDismiss: const [],
      builder: (context, entry) => _XswdEntryVisibility(
        control: control,
        child: KeyedSubtree(
          key: const ValueKey('xswd-approval-toast'),
          child: _decoratedToast(
            context: context,
            style: style,
            child: _XswdApprovalCard(
              notice: notice,
              onOpen: () {
                if (!mounted) return;
                ref
                    .read(xswdRequestProvider.notifier)
                    .requestOpenIfCurrent(notice.token);
              },
              onDeny: () {
                if (!mounted) return;
                if (ref
                    .read(xswdRequestProvider.notifier)
                    .rejectIfCurrent(notice.token)) {
                  _dismissIfToken(notice.token);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _dismissIfToken(Object token) {
    if (!identical(_visibleNotice?.token, token)) return;
    _dismissCurrent();
  }

  void _dismissCurrent() {
    _visibleNotice = null;
    final entry = _entry;
    final control = _entryControl;
    _entry = null;
    _entryControl = null;
    control?.hide();
    if (entry != null && control != null) {
      unawaited(_dismissAfterRender(entry, control));
    }
  }

  Future<void> _dismissAfterRender(
    FToasterEntry entry,
    _XswdToastEntryControl control,
  ) async {
    // Forui 0.26 cannot dismiss before mounting or at zero entrance progress.
    await WidgetsBinding.instance.endOfFrame;
    if (!control.attached) return;
    await WidgetsBinding.instance.endOfFrame;
    if (control.attached && entry.showing) entry.dismiss();
  }

  FToastStyle _toastStyle(BuildContext context) {
    final colors = context.theme.colors;
    final base = context.theme.toasterStyle.toastStyles.primary;
    final borderTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.light ? 0.14 : 0.24,
    );
    final baseDecoration = base.decoration is BoxDecoration
        ? base.decoration as BoxDecoration
        : BoxDecoration(color: colors.toastSurface);

    return FToastStyle(
      constraints: BoxConstraints(
        maxWidth: 396,
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      decoration: baseDecoration.copyWith(
        color: colors.toastSurface,
        border: Border.all(color: borderTint),
        boxShadow: [
          BoxShadow(
            color: colors.toastShadowColor.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      backgroundFilter: base.backgroundFilter,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      iconStyle: base.iconStyle,
      iconSpacing: base.iconSpacing,
      titleTextStyle: base.titleTextStyle,
      titleSpacing: base.titleSpacing,
      descriptionTextStyle: base.descriptionTextStyle,
      suffixSpacing: base.suffixSpacing,
      motion: base.motion,
    );
  }

  Widget _decoratedToast({
    required BuildContext context,
    required FToastStyle style,
    required Widget child,
  }) {
    Widget clipped = Padding(
      padding: style.padding.resolve(Directionality.of(context)),
      child: child,
    );
    final decoration = style.decoration;
    if (decoration is BoxDecoration && decoration.borderRadius != null) {
      clipped = ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: decoration.borderRadius!,
        child: clipped,
      );
    }
    return ConstrainedBox(
      constraints: style.constraints,
      child: DecoratedBox(decoration: style.decoration, child: clipped),
    );
  }

  @override
  void dispose() {
    _visibleNotice = null;
    final entry = _entry;
    final control = _entryControl;
    _entry = null;
    _entryControl = null;
    if (entry != null && control != null) {
      unawaited(_dismissDetachedEntryAfterRender(entry, control));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (toastContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _toastContext = toastContext;
        _restoreCurrentNoticeIfNeeded();
      });
      return widget.child;
    },
  );
}

Future<void> _dismissDetachedEntryAfterRender(
  FToasterEntry entry,
  _XswdToastEntryControl control,
) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!control.attached) return;
  control.hide();
  await WidgetsBinding.instance.endOfFrame;
  if (control.attached && entry.showing) entry.dismiss();
}

class _XswdToastEntryControl extends ChangeNotifier {
  bool attached = false;
  bool visible = true;

  void hide() {
    if (!visible) return;
    visible = false;
    if (attached) notifyListeners();
  }
}

class _XswdEntryVisibility extends StatefulWidget {
  const _XswdEntryVisibility({required this.control, required this.child});

  final _XswdToastEntryControl control;
  final Widget child;

  @override
  State<_XswdEntryVisibility> createState() => _XswdEntryVisibilityState();
}

class _XswdEntryVisibilityState extends State<_XswdEntryVisibility> {
  @override
  void initState() {
    super.initState();
    widget.control.attached = true;
    widget.control.addListener(_onVisibilityChanged);
  }

  void _onVisibilityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.control.removeListener(_onVisibilityChanged);
    widget.control.attached = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.control.visible ? widget.child : const SizedBox.shrink();
}

class _XswdApprovalCard extends StatelessWidget {
  const _XswdApprovalCard({
    required this.notice,
    required this.onOpen,
    required this.onDeny,
  });

  final XswdNotice notice;
  final VoidCallback onOpen;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final requestSurface = colors.primary.withValues(
      alpha: colors.brightness == Brightness.light ? 0.08 : 0.14,
    );
    final requestTextStyle = context.theme.typography.body.xs.copyWith(
      color: Color.lerp(colors.mutedForeground, colors.primary, 0.55),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.05,
    );

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: colors.brightness == Brightness.light ? 0.11 : 0.16,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              FLucideIcons.badgeCheck,
              size: 15,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.applicationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: requestSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    _requestLabel(loc, notice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: requestTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = <Widget>[
      FButton(
        key: const ValueKey('xswd-toast-open'),
        size: .sm,
        mainAxisSize: MainAxisSize.min,
        onPress: onOpen,
        child: Text(loc.open_button),
      ),
      const SizedBox(width: 2),
      FButton(
        key: const ValueKey('xswd-toast-deny'),
        variant: .ghost,
        size: .sm,
        mainAxisSize: MainAxisSize.min,
        onPress: onDeny,
        child: Text(loc.deny),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: actions,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: header),
            const SizedBox(width: 8),
            ...actions,
          ],
        );
      },
    );
  }
}

String _requestLabel(AppLocalizations loc, XswdNotice notice) {
  switch (notice.kind) {
    case XswdNoticeKind.application:
      return loc.connection_request;
    case XswdNoticeKind.permission:
      final method = notice.method;
      return method != null && method.isNotEmpty
          ? '${loc.permission_request} - $method'
          : loc.permission_request;
    case XswdNoticeKind.prefetch:
      final count = notice.permissionCount;
      return count != null && count > 0
          ? '${loc.prefetch_permissions_request} - $count'
          : loc.prefetch_permissions_request;
  }
}
