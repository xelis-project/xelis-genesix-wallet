import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';

part 'wallet_effect.freezed.dart';

@freezed
sealed class WalletEffect with _$WalletEffect {
  const factory WalletEffect.info({required String title}) = WalletInfoEffect;

  const factory WalletEffect.warning({
    required String title,
    String? description,
  }) = WalletWarningEffect;

  const factory WalletEffect.error({
    String? title,
    required String description,
  }) = WalletErrorEffect;

  const factory WalletEffect.failure({
    String? title,
    String? description,
    required AppFailure failure,
  }) = WalletFailureEffect;

  const factory WalletEffect.event({
    String? title,
    required String description,
  }) = WalletEventEffect;

  const factory WalletEffect.xswd({required XswdNotice notice}) =
      WalletXswdEffect;
}

@freezed
sealed class WalletEffectEnvelope with _$WalletEffectEnvelope {
  const factory WalletEffectEnvelope({
    required int id,
    required WalletEffect effect,
  }) = _WalletEffectEnvelope;
}
