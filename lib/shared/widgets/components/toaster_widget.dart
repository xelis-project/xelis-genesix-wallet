import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/shared/models/toast_content.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class ToasterWidget extends ConsumerStatefulWidget {
  const ToasterWidget({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ToasterWidget> createState() => _ToasterWidgetState();
}

class _ToasterWidgetState extends ConsumerState<ToasterWidget> {
  BuildContext? _toastContext;
  late BuildContext _appContext;
  FToasterEntry? _xswdToastEntry;
  final ValueNotifier<int> _visibleXswdToastGeneration = ValueNotifier(0);
  int _nextXswdToastGeneration = 0;

  bool _showStandardDismiss(ToastContent toast) =>
      toast.dismissible &&
      switch (toast) {
        ErrorToastContent() => true,
        _ => toast.sticky,
      };

  @override
  void initState() {
    super.initState();
    ref.listenManual<ToastContent?>(toastProvider, _onToastChanged);
    ref.listenManual<int>(xswdDialogCoordinatorProvider, _onDialogOpenSignal);
  }

  void _onDialogOpenSignal(int? previous, int next) {
    if (previous != next) {
      _dismissXswdToastForDialog();
    }
  }

  void _onToastChanged(ToastContent? prev, ToastContent? next) {
    if (next == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final toastCtx = _toastContext;
      if (toastCtx == null) {
        return;
      }

      if (next.isXswd) {
        _showXswdToast(toastCtx, next);
      } else {
        _showStandardToast(toastCtx, next);
      }

      ref.read(toastProvider.notifier).clear();
    });
  }

  void _dismissXswdToastForDialog() {
    _visibleXswdToastGeneration.value = 0;
    final entry = _xswdToastEntry;
    _xswdToastEntry = null;
    if (entry?.showing ?? false) {
      entry!.dismiss();
    }
  }

  void _showStandardToast(BuildContext toastCtx, ToastContent toast) {
    final spec = _visualSpec(toastCtx, toast);
    final supportReference = toast.supportReference;
    final style = _standardToastStyle(
      toastCtx,
      spec,
      structuredFailure: supportReference != null,
    );

    if (supportReference != null) {
      _showStructuredFailureToast(
        toastCtx,
        toast,
        spec: spec,
        style: style,
        supportReference: supportReference,
      );
      return;
    }

    showRawFToast(
      context: toastCtx,
      style: style,
      duration: _durationFor(toast),
      builder: (context, entry) => FToast(
        style: style,
        clipBehavior: Clip.antiAlias,
        icon: _ToastIconBadge(spec: spec),
        title: Text(toast.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        description: _standardToastDescription(toast),
        suffix: _showStandardDismiss(toast)
            ? FButton.icon(
                variant: .ghost,
                onPress: entry.dismiss,
                child: const Icon(FLucideIcons.x, size: 16),
              )
            : null,
      ),
    );
  }

  void _showStructuredFailureToast(
    BuildContext toastCtx,
    ToastContent toast, {
    required _ToastVisualSpec spec,
    required FToastStyle style,
    required String supportReference,
  }) {
    final loc = ref.read(appLocalizationsProvider);

    showRawFToast(
      context: toastCtx,
      style: style,
      duration: _durationFor(toast),
      swipeToDismiss: toast.dismissible
          ? const [AxisDirection.left, AxisDirection.right]
          : const [],
      builder: (context, entry) => KeyedSubtree(
        key: const ValueKey('structured-error-toast'),
        child: _decoratedRawToast(
          context: context,
          style: style,
          child: _StructuredFailureToastCard(
            title: toast.title,
            description: toast.description!,
            supportReference: supportReference,
            style: style,
            spec: spec,
            localizations: loc,
            onDismiss: _showStandardDismiss(toast) ? entry.dismiss : null,
          ),
        ),
      ),
    );
  }

  Widget? _standardToastDescription(ToastContent toast) {
    final description = toast.description;
    if (description == null) {
      return null;
    }
    return Text(description, maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  Widget _clippedToastContent(FToastStyle style, Widget child) {
    final decoration = _baseToastDecoration(style);
    final borderRadius = decoration.borderRadius;
    if (borderRadius == null) return child;

    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Widget _decoratedRawToast({
    required BuildContext context,
    required FToastStyle style,
    required Widget child,
  }) {
    return ConstrainedBox(
      constraints: style.constraints,
      child: DecoratedBox(
        decoration: style.decoration,
        child: _clippedToastContent(
          style,
          Padding(
            padding: style.padding.resolve(Directionality.of(context)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showXswdToast(BuildContext toastCtx, ToastContent toast) {
    _dismissXswdToastForDialog();
    final spec = _visualSpec(toastCtx, toast);
    final payload = _xswdToastPayload(toast);
    final style = _xswdToastStyle(toastCtx, spec);
    final generation = ++_nextXswdToastGeneration;
    _visibleXswdToastGeneration.value = generation;

    _xswdToastEntry = showRawFToast(
      context: toastCtx,
      style: style,
      duration: null,
      swipeToDismiss: const [],
      builder: (context, entry) {
        return ValueListenableBuilder<int>(
          valueListenable: _visibleXswdToastGeneration,
          child: _decoratedRawToast(
            context: context,
            style: style,
            child: _XswdToastCard(
              payload: payload,
              spec: spec,
              onOpen: toast.actions.isEmpty
                  ? null
                  : () {
                      _dismissXswdToastForDialog();
                      ref
                          .read(xswdRequestProvider.notifier)
                          .requestOpenDialog();
                    },
              onDismiss: toast.dismissible
                  ? () {
                      ref.read(xswdRequestProvider.notifier).clearRequest();
                      _dismissXswdToastForDialog();
                    }
                  : null,
            ),
          ),
          builder: (context, visibleGeneration, child) {
            return visibleGeneration == generation
                ? child!
                : const SizedBox.shrink();
          },
        );
      },
    );
  }

  _XswdToastPayload _xswdToastPayload(ToastContent toast) {
    final loc = ref.read(appLocalizationsProvider);
    final xswdState = ref.read(xswdRequestProvider);
    final summary = xswdState.xswdEventSummary;
    final permissionRequest = xswdState.permissionRpcRequest;
    final prefetchRequest = xswdState.prefetchPermissionsRequest;
    final appInfo = summary?.application;
    final appName = appInfo?.name ?? toast.title;

    return _XswdToastPayload(
      appName: appName,
      requestLabel: _xswdRequestLabel(
        loc,
        summary,
        permissionRequest: permissionRequest,
        prefetchRequest: prefetchRequest,
      ),
      primaryLabel: toast.actions.isEmpty ? null : toast.actions.first.label,
    );
  }

  String _xswdRequestLabel(
    AppLocalizations loc,
    XelisXswdRequest? summary, {
    PermissionRpcRequest? permissionRequest,
    PrefetchPermissionsRequest? prefetchRequest,
  }) {
    if (summary == null) {
      return 'XSWD';
    }

    switch (summary.kind) {
      case XelisXswdRequestKind.application:
        return loc.connection_request;
      case XelisXswdRequestKind.permission:
        final method = permissionRequest?.method.trim();
        if (method != null && method.isNotEmpty) {
          return '${loc.permission_request} - $method';
        }
        return loc.permission_request;
      case XelisXswdRequestKind.prefetchPermissions:
        final count = prefetchRequest?.permissions.length ?? 0;
        return count > 0
            ? '${loc.prefetch_permissions_request} - $count'
            : loc.prefetch_permissions_request;
      case XelisXswdRequestKind.cancel:
        return loc.cancellation_request;
      case XelisXswdRequestKind.applicationDisconnect:
        return loc.app_disconnected;
    }
  }

  Duration? _durationFor(ToastContent toast) {
    if (toast.sticky) {
      return null;
    }

    switch (toast) {
      case InformationToastContent():
        return const Duration(seconds: 3);
      case WarningToastContent():
        return const Duration(seconds: 4);
      case ErrorToastContent():
        return const Duration(seconds: 6);
      case EventToastContent():
        return const Duration(seconds: 4);
      case XswdToastContent():
        return null;
    }
  }

  _ToastVisualSpec _visualSpec(BuildContext context, ToastContent toast) {
    final colors = context.theme.colors;

    switch (toast) {
      case InformationToastContent():
        return _ToastVisualSpec(
          icon: FLucideIcons.info,
          accent: colors.primary,
          titleColor: _tintedTitleColor(colors.foreground, colors.primary),
        );
      case WarningToastContent():
        return _ToastVisualSpec(
          icon: FLucideIcons.triangleAlert,
          accent: colors.warningColor,
          titleColor: _tintedTitleColor(colors.foreground, colors.warningColor),
        );
      case ErrorToastContent():
        return _ToastVisualSpec(
          icon: FLucideIcons.circleAlert,
          accent: colors.destructive,
          titleColor: _tintedTitleColor(colors.foreground, colors.destructive),
        );
      case EventToastContent():
        return _ToastVisualSpec(
          icon: FLucideIcons.sparkles,
          accent: colors.primary,
          titleColor: colors.foreground,
        );
      case XswdToastContent():
        return _ToastVisualSpec(
          icon: FLucideIcons.badgeCheck,
          accent: colors.primary,
          titleColor: colors.foreground,
        );
    }
  }

  Color _tintedTitleColor(Color foreground, Color accent) => Color.lerp(
    foreground,
    accent,
    _appContext.theme.colors.brightness == Brightness.light ? 0.68 : 0.52,
  )!;

  FToastStyle _standardToastStyle(
    BuildContext context,
    _ToastVisualSpec spec, {
    required bool structuredFailure,
  }) {
    final colors = context.theme.colors;
    final base = context.theme.toasterStyle.toastStyles.primary;
    final borderTint = spec.accent.withValues(
      alpha: colors.brightness == Brightness.light ? 0.18 : 0.34,
    );

    return FToastStyle(
      constraints: structuredFailure
          ? BoxConstraints(
              maxWidth: base.constraints.maxWidth,
              maxHeight: _structuredToastMaxHeight(context),
            )
          : base.constraints,
      decoration: _baseToastDecoration(base).copyWith(
        color: colors.toastSurface,
        border: Border.all(color: borderTint),
      ),
      backgroundFilter: base.backgroundFilter,
      padding: base.padding,
      iconStyle: base.iconStyle,
      iconSpacing: base.iconSpacing,
      titleTextStyle: base.titleTextStyle.copyWith(color: spec.titleColor),
      titleSpacing: base.titleSpacing,
      descriptionTextStyle: base.descriptionTextStyle.copyWith(
        color: structuredFailure ? colors.foreground : colors.mutedForeground,
        fontWeight: structuredFailure ? FontWeight.w600 : null,
        overflow: structuredFailure ? TextOverflow.visible : null,
      ),
      suffixSpacing: base.suffixSpacing,
      motion: base.motion,
    );
  }

  double _structuredToastMaxHeight(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final availableHeight =
        mediaSize.height - safePadding.vertical - 36; // toaster outer padding
    return math.max(56, math.min(360, availableHeight * 0.5));
  }

  FToastStyle _xswdToastStyle(BuildContext context, _ToastVisualSpec spec) {
    final colors = context.theme.colors;
    final base = context.theme.toasterStyle.toastStyles.primary;
    final borderTint = spec.accent.withValues(
      alpha: colors.brightness == Brightness.light ? 0.14 : 0.24,
    );

    return FToastStyle(
      constraints: const BoxConstraints(maxWidth: 396, maxHeight: 116),
      decoration: _baseToastDecoration(base).copyWith(
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

  BoxDecoration _baseToastDecoration(FToastStyle style) =>
      style.decoration is BoxDecoration
      ? style.decoration as BoxDecoration
      : BoxDecoration(color: _appContext.theme.colors.toastSurface);

  @override
  void dispose() {
    _dismissXswdToastForDialog();
    _visibleXswdToastGeneration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _appContext = context;

    return FToaster(
      child: Builder(
        builder: (toastContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _toastContext = toastContext;
          });
          return widget.child;
        },
      ),
    );
  }
}

class _StructuredFailureToastCard extends StatefulWidget {
  const _StructuredFailureToastCard({
    required this.title,
    required this.description,
    required this.supportReference,
    required this.style,
    required this.spec,
    required this.localizations,
    required this.onDismiss,
  });

  final String title;
  final String description;
  final String supportReference;
  final FToastStyle style;
  final _ToastVisualSpec spec;
  final AppLocalizations localizations;
  final VoidCallback? onDismiss;

  @override
  State<_StructuredFailureToastCard> createState() =>
      _StructuredFailureToastCardState();
}

class _StructuredFailureToastCardState
    extends State<_StructuredFailureToastCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final titleStyle = widget.style.titleTextStyle.copyWith(
      overflow: TextOverflow.visible,
    );
    final messageStyle = widget.style.descriptionTextStyle.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.visible,
    );
    final supportStyle = widget.style.descriptionTextStyle.copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.w400,
      height: 1.25,
      overflow: TextOverflow.visible,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            key: const ValueKey('structured-error-scroll'),
            controller: _scrollController,
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: titleStyle),
                SizedBox(height: widget.style.titleSpacing),
                Text(widget.description, style: messageStyle),
                const SizedBox(height: 8),
                _CopyableSupportReference(
                  reference: widget.supportReference,
                  displayText: widget.localizations.support_reference(
                    widget.supportReference,
                  ),
                  copyLabel: widget.localizations.copy,
                  copiedLabel: widget.localizations.copied_to_clipboard,
                  style: supportStyle,
                ),
              ],
            ),
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToastIconBadge(spec: widget.spec),
            SizedBox(width: widget.style.iconSpacing),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: body,
              ),
            ),
            if (widget.onDismiss != null) ...[
              SizedBox(width: widget.style.suffixSpacing),
              FButton.icon(
                key: const ValueKey('structured-error-dismiss'),
                variant: .ghost,
                size: .sm,
                semanticsLabel: widget.localizations.close,
                onPress: widget.onDismiss,
                child: const Icon(FLucideIcons.x, size: 16),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CopyableSupportReference extends StatefulWidget {
  const _CopyableSupportReference({
    required this.reference,
    required this.displayText,
    required this.copyLabel,
    required this.copiedLabel,
    required this.style,
  });

  final String reference;
  final String displayText;
  final String copyLabel;
  final String copiedLabel;
  final TextStyle style;

  @override
  State<_CopyableSupportReference> createState() =>
      _CopyableSupportReferenceState();
}

class _CopyableSupportReferenceState extends State<_CopyableSupportReference> {
  Timer? _feedbackTimer;
  bool _copied = false;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.reference));
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'genesix toaster',
          context: ErrorDescription('while copying a support reference'),
        ),
      );
      return;
    }

    if (!mounted) return;
    _feedbackTimer?.cancel();
    setState(() => _copied = true);
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _copied ? widget.copiedLabel : widget.copyLabel;

    return Semantics(
      key: const ValueKey('support-reference-semantics'),
      button: true,
      label: widget.displayText,
      hint: actionLabel,
      onTap: _copy,
      child: ExcludeSemantics(
        child: FTooltip(
          tipBuilder: (context, controller) => Text(actionLabel),
          child: SizedBox(
            width: double.infinity,
            child: FButton.raw(
              key: const ValueKey('support-reference-copy'),
              variant: .ghost,
              size: .sm,
              onPress: _copy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(widget.displayText, style: widget.style),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        _copied ? FLucideIcons.check : FLucideIcons.copy,
                        key: ValueKey(_copied),
                        size: 14,
                        color: widget.style.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastVisualSpec {
  const _ToastVisualSpec({
    required this.icon,
    required this.accent,
    required this.titleColor,
  });

  final IconData icon;
  final Color accent;
  final Color titleColor;
}

class _ToastIconBadge extends StatelessWidget {
  const _ToastIconBadge({required this.spec});

  final _ToastVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final background = spec.accent.withValues(
      alpha: colors.brightness == Brightness.light ? 0.12 : 0.2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(spec.icon, size: 16, color: spec.accent),
      ),
    );
  }
}

class _XswdToastPayload {
  const _XswdToastPayload({
    required this.appName,
    required this.requestLabel,
    required this.primaryLabel,
  });

  final String appName;
  final String requestLabel;
  final String? primaryLabel;
}

class _XswdToastCard extends StatelessWidget {
  const _XswdToastCard({
    required this.payload,
    required this.spec,
    required this.onOpen,
    required this.onDismiss,
  });

  final _XswdToastPayload payload;
  final _ToastVisualSpec spec;
  final VoidCallback? onOpen;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final requestSurface = spec.accent.withValues(
      alpha: colors.brightness == Brightness.light ? 0.08 : 0.14,
    );
    final requestTextStyle = context.theme.typography.body.xs.copyWith(
      color: Color.lerp(colors.mutedForeground, spec.accent, 0.55),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.05,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: spec.accent.withValues(
                  alpha: colors.brightness == Brightness.light ? 0.11 : 0.16,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(spec.icon, size: 15, color: spec.accent),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payload.appName,
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
                        payload.requestLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: requestTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onOpen != null && payload.primaryLabel != null)
              FButton(
                size: .sm,
                mainAxisSize: MainAxisSize.min,
                onPress: onOpen,
                child: Text(payload.primaryLabel!),
              ),
            if (onDismiss != null) ...[
              const SizedBox(width: 2),
              FButton.icon(
                variant: .ghost,
                size: .sm,
                onPress: onDismiss,
                child: const Icon(FLucideIcons.x, size: 16),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
