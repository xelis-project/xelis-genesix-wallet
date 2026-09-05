import 'package:genesix/features/router/extra_type_adapter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Non-restorable codec for an in-memory XSWD session capability.
///
/// GoRouter keeps the original object for ordinary imperative navigation. Its
/// serialized restoration form is deliberately a constant sentinel without a
/// native token or application metadata. Restoring it yields a detached,
/// non-authoritative reference that cannot match a live wallet session.
class XswdSessionReferenceAdapter
    extends ExtraTypeAdapter<XelisXswdSessionReference> {
  const XswdSessionReferenceAdapter();

  static const _detachedSentinel = 'non_restorable';

  @override
  String get type => 'xswd_session_reference';

  @override
  Object? encode(XelisXswdSessionReference value) => _detachedSentinel;

  @override
  XelisXswdSessionReference decode(Object? payload) {
    if (payload != _detachedSentinel) {
      throw const FormatException('Invalid XSWD session route reference');
    }
    return XelisXswdSessionReference.detached();
  }
}
