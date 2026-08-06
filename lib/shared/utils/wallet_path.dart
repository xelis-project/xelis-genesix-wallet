import 'package:path/path.dart' as p;

const Set<String> _windowsReservedWalletNames = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'CLOCK\$',
  'CONIN\$',
  'CONOUT\$',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'COM¹',
  'COM²',
  'COM³',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
  'LPT¹',
  'LPT²',
  'LPT³',
};

final RegExp _windowsInvalidWalletNameCharacters = RegExp(r'[<>:"/\\|?*]');

/// Thrown before filesystem access when a wallet name is not a safe path leaf.
///
/// The rejected value is deliberately omitted so exception formatting remains
/// safe for logs and user-facing fallback handlers.
final class InvalidWalletNameException implements Exception {
  const InvalidWalletNameException();

  @override
  String toString() =>
      'InvalidWalletNameException: the wallet name is not a safe path name';
}

/// Thrown when an existing wallet path is not a direct directory entry.
///
/// This rejects files and symbolic links without retaining the path in the
/// exception, keeping fallback logs and UI safe.
final class UnsafeWalletPathException implements Exception {
  const UnsafeWalletPathException();

  @override
  String toString() =>
      'UnsafeWalletPathException: the wallet path is not a direct directory';
}

/// Returns whether [name] is one portable, filesystem-safe path component.
bool isValidWalletName(String name) {
  if (name.isEmpty || name.trim().isEmpty || name == '.' || name == '..') {
    return false;
  }

  if (_isAbsoluteOrUncPath(name) || name.contains('/') || name.contains(r'\')) {
    return false;
  }

  if (name.codeUnits.any((unit) => unit <= 0x1f || unit == 0x7f)) {
    return false;
  }

  if (_windowsInvalidWalletNameCharacters.hasMatch(name) ||
      name.endsWith('.') ||
      name.endsWith(' ')) {
    return false;
  }

  final windowsDeviceStem = name.split('.').first.toUpperCase();
  return !_windowsReservedWalletNames.contains(windowsDeviceStem);
}

/// Resolves a wallet path strictly below one network-owned wallet directory.
///
/// [walletsDirectory] may be absolute on native platforms or relative for the
/// web storage backend. [walletName] is always treated as an opaque leaf name,
/// never as a path supplied by the caller.
String resolveWalletPath({
  required String walletsDirectory,
  required String networkName,
  required String walletName,
  p.Context? pathContext,
}) {
  if (!isValidWalletName(walletName)) {
    throw const InvalidWalletNameException();
  }

  final context = pathContext ?? p.context;
  final networkDirectory = context.normalize(
    context.join(walletsDirectory, networkName),
  );
  final candidate = context.normalize(
    context.join(networkDirectory, walletName),
  );

  if (candidate == networkDirectory ||
      !context.isWithin(networkDirectory, candidate)) {
    throw const InvalidWalletNameException();
  }

  return candidate;
}

bool _isAbsoluteOrUncPath(String value) {
  return p.posix.isAbsolute(value) ||
      p.windows.isAbsolute(value) ||
      p.url.isAbsolute(value) ||
      value.startsWith(r'\\') ||
      value.startsWith('//');
}
