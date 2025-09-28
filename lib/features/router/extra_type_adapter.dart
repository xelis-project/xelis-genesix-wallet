typedef Json = Map<String, dynamic>;

abstract class ExtraTypeAdapter<T> {
  const ExtraTypeAdapter();

  String get type;

  bool canEncode(Object? value) => value is T;

  Object? encode(T value);

  T decode(Object? payload);
}
