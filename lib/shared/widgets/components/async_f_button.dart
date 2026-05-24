import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class AsyncFButton extends StatelessWidget {
  const AsyncFButton({
    required this.isLoading,
    required this.onPress,
    required this.child,
    this.variant = FButtonVariant.primary,
    this.size = FButtonSizeVariant.md,
    this.style = const FButtonStyleDelta.context(),
    this.mainAxisSize = MainAxisSize.max,
    this.prefix,
    this.suffix,
    super.key,
  });

  final bool isLoading;
  final VoidCallback? onPress;
  final Widget child;
  final FButtonVariant variant;
  final FButtonSizeVariant size;
  final FButtonStyleDelta style;
  final MainAxisSize mainAxisSize;
  final Widget? prefix;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: variant,
      size: size,
      style: style,
      mainAxisSize: mainAxisSize,
      prefix: isLoading ? const FCircularProgress.loader() : prefix,
      suffix: suffix,
      onPress: isLoading ? null : onPress,
      child: child,
    );
  }
}
