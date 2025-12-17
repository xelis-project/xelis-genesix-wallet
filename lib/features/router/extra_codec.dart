import 'dart:convert';

import 'package:genesix/features/router/extra_type_adapter.dart';

class ExtraCodec extends Codec<Object?, Object?> {
  const ExtraCodec({required this.adapters});

  final List<ExtraTypeAdapter<dynamic>> adapters;

  @override
  Converter<Object?, Object?> get encoder => _ExtraEncoder(adapters: adapters);

  @override
  Converter<Object?, Object?> get decoder => _ExtraDecoder(adapters: adapters);
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  _ExtraEncoder({required this.adapters});

  final List<ExtraTypeAdapter<dynamic>> adapters;

  @override
  Object? convert(Object? input) {
    if (input == null) return null;

    // Primitive types
    if (input is num || input is String || input is bool) return input;
    if (input is List) {
      return input.map(convert).toList();
    }
    if (input is Map) {
      return input.map((k, v) => MapEntry(k, convert(v)));
    }

    for (final a in adapters) {
      if (a.canEncode(input)) {
        final encoded = a.encode(input);
        return <Object?>[a.type, encoded];
      }
    }

    throw FormatException(
      'Unable to encode input: $input of type ${input.runtimeType}. Add an ExtraTypeAdapter for this type.',
    );
  }
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  _ExtraDecoder({required this.adapters});

  final List<ExtraTypeAdapter<dynamic>> adapters;

  @override
  Object? convert(Object? input) {
    if (input == null) return null;

    if (input is List) {
      // Awaiting a list of [type, payload]
      if (input.length == 2 && input[0] is String) {
        final type = input[0] as String;
        final payload = input[1];
        for (final a in adapters) {
          if (a.type == type) {
            return a.decode(payload);
          }
        }
        // Unknown type, we return the original input
        return input;
      }
      // Otherwise, we decode each item in the list
      return input.map(convert).toList();
    }

    if (input is Map) {
      return input.map((k, v) => MapEntry(k, convert(v)));
    }

    // Primitive types
    return input;
  }
}
