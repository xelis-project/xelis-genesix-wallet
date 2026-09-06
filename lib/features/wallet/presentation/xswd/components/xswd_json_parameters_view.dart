import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

const _maxPreviewCharacters = 512;
const _maxPreviewNodes = 32;
const _maxPreviewDepth = 4;
const _maxPreviewCollectionEntries = 3;
const _maxPreviewStringCharacters = 64;
const _maxPreviewIntegerBits = 512;

final class XswdJsonPreview {
  const XswdJsonPreview({
    required this.text,
    required this.isTruncated,
    required this.visitedNodes,
  });

  final String text;
  final bool isTruncated;

  /// Number of values inspected while producing the preview.
  ///
  /// Exposed so tests can enforce that passive rendering stays independent of
  /// the size of an already budget-validated XSWD payload.
  final int visitedNodes;
}

/// Produces a bounded JSON-like preview without serializing the complete value.
///
/// XSWD payload decoding accepts only JSON scalars, [BigInt], lists, and maps.
/// Unsupported objects are represented by a fixed marker and are never
/// interpolated, so an unexpected object's `toString` cannot expose data.
@visibleForTesting
XswdJsonPreview xswdJsonPreview(Object? value) {
  final builder = _XswdJsonPreviewBuilder();
  builder.writeValue(value, depth: 0);
  return builder.finish();
}

/// Shows standard XSWD permission parameters without eagerly serializing them.
class XswdJsonParametersView extends StatelessWidget {
  const XswdJsonParametersView({
    required this.parameters,
    required this.loc,
    super.key,
  });

  final Map<String, dynamic> parameters;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final preview = xswdJsonPreview(parameters);
    return Column(
      key: const ValueKey('xswd-json-parameters'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          preview.text,
          key: const ValueKey('xswd-json-parameters-preview'),
          style: context.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        if (preview.isTruncated) ...[
          const SizedBox(height: Spaces.small),
          FButton(
            key: const ValueKey('xswd-json-parameters-reveal'),
            onPress: () => _reveal(context),
            child: Text(loc.more_details),
          ),
        ],
      ],
    );
  }

  void _reveal(BuildContext context) {
    // This is intentionally the only complete serialization on the review
    // path. It follows an explicit user action and preserves authored BigInts.
    final value = serializeBigIntJson(parameters, indent: '  ');
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text(loc.parameters),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: XswdFullValueView(
            value: value,
            key: const ValueKey('xswd-json-parameters-full'),
            chunkKeyPrefix: 'xswd-json-parameters-full',
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }
}

final class _XswdJsonPreviewBuilder {
  final _buffer = StringBuffer();
  var _visitedNodes = 0;
  var _truncated = false;

  int get _remaining => _maxPreviewCharacters - 1 - _buffer.length;

  void writeValue(Object? value, {required int depth}) {
    if (_visitedNodes >= _maxPreviewNodes ||
        depth > _maxPreviewDepth ||
        _remaining <= 0) {
      _truncated = true;
      return;
    }
    _visitedNodes++;

    switch (value) {
      case null:
        _write('null');
      case final bool value:
        _write(value ? 'true' : 'false');
      case final int value:
        _write(value.toString());
      case final BigInt value:
        _writeBigInt(value);
      case final double value:
        _write(value.isFinite ? jsonEncode(value) : '<invalid number>');
        if (!value.isFinite) _truncated = true;
      case final String value:
        _writeString(value);
      case final List<dynamic> values:
        _writeList(values, depth);
      case final Map<dynamic, dynamic> values:
        _writeMap(values, depth);
      default:
        _write('<unsupported>');
        _truncated = true;
    }
  }

  void _writeBigInt(BigInt value) {
    if (value.bitLength <= _maxPreviewIntegerBits) {
      _write(value.toString());
      return;
    }
    final approximateDigits =
        ((value.bitLength - 1) * math.log(2) / math.ln10).floor() + 1;
    _write('<integer: ~$approximateDigits digits>');
    _truncated = true;
  }

  void _writeString(String value) {
    if (value.length <= _maxPreviewStringCharacters) {
      _write(jsonEncode(value));
      return;
    }
    final prefix = _safePrefix(value, _maxPreviewStringCharacters);
    _write(jsonEncode('$prefix…'));
    _truncated = true;
  }

  void _writeList(List<dynamic> values, int depth) {
    _write('[');
    final shown = math.min(values.length, _maxPreviewCollectionEntries);
    for (var index = 0; index < shown; index++) {
      if (index > 0) _write(', ');
      writeValue(values[index], depth: depth + 1);
      if (_remaining <= 0) break;
    }
    if (values.length > shown) _truncated = true;
    _write(']');
  }

  void _writeMap(Map<dynamic, dynamic> values, int depth) {
    _write('{');
    var shown = 0;
    for (final entry in values.entries) {
      if (shown >= _maxPreviewCollectionEntries || _remaining <= 0) break;
      if (shown > 0) _write(', ');
      if (entry.key case final String key) {
        _writeString(key);
      } else {
        _write('"<unsupported key>"');
        _truncated = true;
      }
      _write(': ');
      writeValue(entry.value, depth: depth + 1);
      shown++;
    }
    if (values.length > shown) _truncated = true;
    _write('}');
  }

  void _write(String value) {
    if (_remaining <= 0) {
      _truncated = true;
      return;
    }
    if (value.length <= _remaining) {
      _buffer.write(value);
      return;
    }
    _buffer.write(_safePrefix(value, _remaining));
    _truncated = true;
  }

  XswdJsonPreview finish() {
    final raw = _buffer.toString();
    final text = _truncated
        ? '${_safePrefix(raw, _maxPreviewCharacters - 1)}…'
        : raw;
    return XswdJsonPreview(
      text: text,
      isTruncated: _truncated,
      visitedNodes: _visitedNodes,
    );
  }
}

String _safePrefix(String value, int length) {
  if (value.length <= length) return value;
  var end = length;
  if (end > 0) {
    final lastUnit = value.codeUnitAt(end - 1);
    if (lastUnit >= 0xd800 && lastUnit <= 0xdbff) end--;
  }
  return value.substring(0, end);
}
