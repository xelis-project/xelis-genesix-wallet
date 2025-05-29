// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'multisig_participant.freezed.dart';

part 'multisig_participant.g.dart';

@freezed
abstract class MultisigParticipant with _$MultisigParticipant {
  const factory MultisigParticipant({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'address') required String address,
  }) = _MultisigParticipant;

  factory MultisigParticipant.fromJson(Map<String, dynamic> json) =>
      _$MultisigParticipantFromJson(json);
}
