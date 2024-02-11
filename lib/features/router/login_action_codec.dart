import 'dart:convert';

enum LoginAction {
  create,
  open;

  factory LoginAction.fromStr(String value) {
    switch (value) {
      case 'create':
        return LoginAction.create;
      case 'open':
        return LoginAction.open;
      default:
        throw Exception('Unknown login action: $value');
    }
  }
}

/// A codec that can serialize [LoginAction] for GoRouter.
class LoginActionCodec extends Codec<Object?, Object?> {
  const LoginActionCodec();

  @override
  Converter<Object?, Object?> get decoder => const _LoginActionDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _LoginActionEncoder();
}

class _LoginActionDecoder extends Converter<Object?, Object?> {
  const _LoginActionDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    final List<Object?> inputAsList = input as List<Object?>;
    if (inputAsList[0] == 'LoginAction') {
      return LoginAction.fromStr(inputAsList[1] as String);
    }
    throw FormatException('Unable to parse input: $input');
  }
}

class _LoginActionEncoder extends Converter<Object?, Object?> {
  const _LoginActionEncoder();

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
