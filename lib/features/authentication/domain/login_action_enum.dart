import 'dart:convert';

enum LoginAction {
  create,
  open,
}

LoginAction? fromStr(String value) {
  switch (value) {
    case 'create':
      return LoginAction.create;
    case 'open':
      return LoginAction.open;
    default:
      return null;
  }
}

/// A codec that can serialize [LoginAction] for GoRouter.
class MyExtraCodec extends Codec<Object?, Object?> {
  /// Create a codec.
  const MyExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _MyExtraDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _MyExtraEncoder();
}

class _MyExtraDecoder extends Converter<Object?, Object?> {
  const _MyExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    final List<Object?> inputAsList = input as List<Object?>;
    if (inputAsList[0] == 'LoginAction') {
      return fromStr(inputAsList[1] as String) as LoginAction;
    }
    throw FormatException('Unable to parse input: $input');
  }
}

class _MyExtraEncoder extends Converter<Object?, Object?> {
  const _MyExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    switch (input.runtimeType) {
      case const (LoginAction):
        return <Object?>['LoginAction', (input as LoginAction).name];
      default:
        throw FormatException('Cannot encode type ${input.runtimeType}');
    }
  }
}
