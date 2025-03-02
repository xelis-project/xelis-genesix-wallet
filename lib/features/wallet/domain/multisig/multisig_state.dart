// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'multisig_participant.dart';

part 'multisig_state.freezed.dart';

part 'multisig_state.g.dart';

@freezed
abstract class MultisigState with _$MultisigState {
  const factory MultisigState({
    @JsonKey(name: 'participants')
    @Default({})
    Set<MultisigParticipant> participants,
    @JsonKey(name: 'threshold') @Default(0) int threshold,
    @JsonKey(name: 'topoheight') @Default(0) int topoheight,
  }) = _MultisigState;

  const MultisigState._();

  factory MultisigState.fromJson(Map<String, dynamic> json) =>
      _$MultisigStateFromJson(json);

  bool get isSetup =>
      participants.isNotEmpty && threshold > 0 && topoheight > 0;
}
