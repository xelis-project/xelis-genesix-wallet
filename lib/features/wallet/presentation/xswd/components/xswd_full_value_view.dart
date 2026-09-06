import 'package:material_ui/material_ui.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

/// Lazily lays out a complete revealed XSWD value in bounded text chunks.
///
/// Chunking changes only line wrapping at chunk boundaries. It neither removes
/// nor rewrites any character from [value].
class XswdFullValueView extends StatelessWidget {
  const XswdFullValueView({
    required this.value,
    required this.chunkKeyPrefix,
    this.monospace = true,
    super.key,
  });

  static const _targetChunkCharacters = 2048;
  static const _minimumLineSplitCharacters = 1024;

  final String value;
  final String chunkKeyPrefix;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final chunks = xswdChunkBounds(value);
    return ListView.builder(
      key: ValueKey('$chunkKeyPrefix-list'),
      itemCount: chunks.length,
      itemBuilder: (context, index) {
        final chunk = chunks[index];
        return SelectableText(
          value.substring(chunk.start, chunk.end),
          key: ValueKey('$chunkKeyPrefix-chunk-$index'),
          style: context.bodySmall?.copyWith(
            fontFamily: monospace ? 'monospace' : null,
          ),
        );
      },
    );
  }
}

@visibleForTesting
List<({int start, int end})> xswdChunkBounds(String value) {
  if (value.isEmpty) return const [(start: 0, end: 0)];
  final chunks = <({int start, int end})>[];
  var start = 0;
  while (start < value.length) {
    var end = (start + XswdFullValueView._targetChunkCharacters).clamp(
      0,
      value.length,
    );
    if (end < value.length) {
      final minimumSplit =
          start + XswdFullValueView._minimumLineSplitCharacters;
      var lineEnd = -1;
      for (var index = end - 1; index >= minimumSplit; index--) {
        if (value.codeUnitAt(index) == 0x0a) {
          lineEnd = index;
          break;
        }
      }
      if (lineEnd >= minimumSplit) {
        end = lineEnd + 1;
      } else if (_isHighSurrogate(value.codeUnitAt(end - 1))) {
        end--;
      }
    }
    chunks.add((start: start, end: end));
    start = end;
  }
  return chunks;
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xd800 && codeUnit <= 0xdbff;
