import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authored wallet imports use only the package-root public facade', () {
    for (final file in _authoredDartFiles()) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(
          matches(
            RegExp(r'''import\s+['"]package:xelis_wallet_flutter/src/'''),
          ),
        ),
        reason: file.path,
      );
      expect(
        source,
        isNot(
          matches(
            RegExp(r'''import\s+['"]package:xelis_wallet_flutter/api/'''),
          ),
        ),
        reason: file.path,
      );
      expect(
        source,
        isNot(
          matches(RegExp(r'''import\s+['"]package:flutter_rust_bridge/''')),
        ),
        reason: file.path,
      );
    }
  });

  test('Genesix does not embed a Rust or generated bridge toolchain', () {
    for (final directory in <String>[
      'rust',
      'rust_builder',
      'lib/src/generated/rust_bridge',
    ]) {
      expect(Directory(directory).existsSync(), isFalse, reason: directory);
    }
    expect(File('flutter_rust_bridge.yaml').existsSync(), isFalse);
  });
}

Iterable<File> _authoredDartFiles() sync* {
  for (final root in <String>['lib', 'test']) {
    yield* Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => !file.path.contains(
            'lib${Platform.pathSeparator}src${Platform.pathSeparator}generated',
          ),
        );
  }
}
