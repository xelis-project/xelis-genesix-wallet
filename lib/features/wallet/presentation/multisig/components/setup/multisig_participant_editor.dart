import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/address_book/select_address_dialog.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_animated_switcher.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

const _maxMultisigParticipants = 255;

Duration _participantMotionDuration(BuildContext context) {
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return animationsDisabled
      ? Duration.zero
      : const Duration(milliseconds: AppDurations.animNormal);
}

class MultisigParticipantEditor extends StatefulWidget {
  const MultisigParticipantEditor({
    required this.loc,
    required this.initialParticipants,
    required this.enabled,
    required this.validateAddress,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations loc;
  final List<String> initialParticipants;
  final bool enabled;
  final String? Function(String address) validateAddress;
  final ValueChanged<List<String>> onChanged;

  @override
  State<MultisigParticipantEditor> createState() =>
      _MultisigParticipantEditorState();
}

class _MultisigParticipantEditorState extends State<MultisigParticipantEditor> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final List<String> _participants;

  String _observedText = '';
  String? _error;
  bool _isSettling = false;
  int _settlingGeneration = 0;

  bool get _isAtLimit => _participants.length >= _maxMultisigParticipants;
  bool get _inputEnabled => widget.enabled && !_isSettling && !_isAtLimit;

  @override
  void initState() {
    super.initState();
    _participants = List.of(widget.initialParticipants);
  }

  @override
  void dispose() {
    _settlingGeneration++;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: Text(widget.loc.participants),
      subtitle: Text(widget.loc.multisig_setup_participants_description),
      child: Padding(
        padding: const EdgeInsets.only(top: Spaces.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.medium,
          children: [
            _ParticipantComposer(
              loc: widget.loc,
              controller: _controller,
              focusNode: _focusNode,
              error: _error,
              enabled: _inputEnabled,
              onChanged: _handleInputChanged,
              onPaste: _pasteAddress,
              onAddressBook: _selectFromAddressBook,
              onAdd: _addParticipant,
            ),
            Row(
              children: [
                FBadge(
                  variant: .outline,
                  child: Text(
                    widget.loc.multisig_setup_participant_count(
                      _participants.length,
                    ),
                  ),
                ),
                if (_isAtLimit) ...[
                  const SizedBox(width: Spaces.small),
                  Expanded(
                    child: Text(
                      widget.loc.multisig_setup_max_participants,
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Column(
              children: [
                MultisigSetupAnimatedSwitcher(
                  duration: _participantMotionDuration(context),
                  child: _participants.isEmpty
                      ? _EmptyParticipantList(
                          key: const ValueKey('empty-participant-list'),
                          loc: widget.loc,
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('populated-participant-list'),
                        ),
                ),
                AnimatedList.separated(
                  key: _listKey,
                  initialItemCount: _participants.length,
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemBuilder: (context, index, animation) =>
                      _AnimatedParticipantTile(
                        key: ValueKey(_participants[index]),
                        animation: animation,
                        index: index,
                        address: _participants[index],
                        onRemove: widget.enabled && !_isSettling
                            ? () => _removeParticipant(index)
                            : null,
                        removeLabel:
                            widget.loc.multisig_setup_remove_participant,
                      ),
                  separatorBuilder: (context, index, animation) =>
                      _AnimatedParticipantSeparator(animation: animation),
                  removedSeparatorBuilder: (context, index, animation) =>
                      _AnimatedParticipantSeparator(animation: animation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleInputChanged(String value) {
    if (value == _observedText) return;
    _observedText = value;
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _pasteAddress() async {
    if (!_inputEnabled) return;

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final address = clipboard?.text?.trim();
    if (!mounted || address == null || address.isEmpty) return;

    _setInputText(address);
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _selectFromAddressBook() async {
    if (!_inputEnabled) return;

    final address = await showAppDialog<String>(
      context: context,
      builder: (_, _, animation) {
        return SelectAddressDialog(animation);
      },
    );
    if (!mounted || !_inputEnabled || address == null) return;

    final normalizedAddress = address.trim();
    if (normalizedAddress.isEmpty) return;

    _setInputText(normalizedAddress);
    if (_error != null) setState(() => _error = null);
    _focusNode.requestFocus();
  }

  void _addParticipant() {
    if (!_inputEnabled) return;

    final address = _controller.text.trim();
    final error = widget.validateAddress(address);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final index = _participants.length;
    final duration = _participantMotionDuration(context);
    final generation = ++_settlingGeneration;
    setState(() {
      _participants.add(address);
      _error = null;
      _isSettling = true;
    });
    widget.onChanged(List.unmodifiable(_participants));
    _listKey.currentState?.insertItem(index, duration: duration);

    if (duration == Duration.zero) {
      _finishInsertion(generation);
    } else {
      unawaited(_completeInsertion(generation, duration));
    }
  }

  Future<void> _completeInsertion(int generation, Duration duration) async {
    await Future<void>.delayed(duration);
    if (!mounted || generation != _settlingGeneration) return;
    _finishInsertion(generation);
  }

  void _finishInsertion(int generation) {
    if (!mounted || generation != _settlingGeneration) return;
    _setInputText('');
    setState(() => _isSettling = false);
    _focusNode.requestFocus();
  }

  void _removeParticipant(int index) {
    if (!widget.enabled || _isSettling || index >= _participants.length) {
      return;
    }

    final removedAddress = _participants[index];
    final duration = _participantMotionDuration(context);
    final generation = ++_settlingGeneration;
    setState(() {
      _participants.removeAt(index);
      _isSettling = true;
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _AnimatedParticipantTile(
        animation: animation,
        index: index,
        address: removedAddress,
        onRemove: null,
        removeLabel: widget.loc.multisig_setup_remove_participant,
      ),
      duration: duration,
    );
    widget.onChanged(List.unmodifiable(_participants));

    if (duration == Duration.zero) {
      setState(() => _isSettling = false);
    } else {
      unawaited(_completeRemoval(generation, duration));
    }
  }

  Future<void> _completeRemoval(int generation, Duration duration) async {
    await Future<void>.delayed(duration);
    if (!mounted || generation != _settlingGeneration) return;
    setState(() => _isSettling = false);
  }

  void _setInputText(String value) {
    _observedText = value;
    _controller.text = value;
  }
}

class _ParticipantComposer extends StatelessWidget {
  const _ParticipantComposer({
    required this.loc,
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.enabled,
    required this.onChanged,
    required this.onPaste,
    required this.onAddressBook,
    required this.onAdd,
  });

  final AppLocalizations loc;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final VoidCallback onAddressBook;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.smallMedium,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FTextField(
                enabled: enabled,
                control: .managed(
                  controller: controller,
                  onChange: (value) => onChanged(value.text),
                ),
                focusNode: focusNode,
                autocorrect: false,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                label: Text(loc.multisig_setup_participant_address),
                hint: loc.wallet_address_capitalize,
                error: error == null ? null : Text(error!),
                clearable: (value) => enabled && value.text.isNotEmpty,
                onSubmit: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: Spaces.small),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _ParticipantInputActions(
                loc: loc,
                enabled: enabled,
                onPaste: onPaste,
                onAddressBook: onAddressBook,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: FButton(
            onPress: enabled ? onAdd : null,
            prefix: const Icon(FLucideIcons.plus, size: 18),
            child: Text(loc.multisig_setup_add_participant),
          ),
        ),
      ],
    );
  }
}

class _ParticipantInputActions extends StatelessWidget {
  const _ParticipantInputActions({
    required this.loc,
    required this.enabled,
    required this.onPaste,
    required this.onAddressBook,
  });

  final AppLocalizations loc;
  final bool enabled;
  final VoidCallback onPaste;
  final VoidCallback onAddressBook;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spaces.extraSmall,
      children: [
        FTooltip(
          tipBuilder: (context, controller) =>
              Text(loc.multisig_setup_paste_address),
          child: FButton.icon(
            variant: .outline,
            semanticsLabel: loc.multisig_setup_paste_address,
            onPress: enabled ? onPaste : null,
            child: const Icon(FLucideIcons.clipboardPaste),
          ),
        ),
        FTooltip(
          tipBuilder: (context, controller) => Text(loc.address_book),
          child: FButton.icon(
            variant: .outline,
            semanticsLabel: loc.address_book,
            onPress: enabled ? onAddressBook : null,
            child: const Icon(FLucideIcons.bookUser),
          ),
        ),
      ],
    );
  }
}

class _EmptyParticipantList extends StatelessWidget {
  const _EmptyParticipantList({required this.loc, super.key});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: Column(
        spacing: Spaces.small,
        children: [
          Icon(
            FLucideIcons.users,
            size: 28,
            color: context.theme.colors.mutedForeground,
          ),
          Text(
            loc.multisig_setup_no_participants,
            textAlign: TextAlign.center,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedParticipantSeparator extends StatelessWidget {
  const _AnimatedParticipantSeparator({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return SizeTransition(
      sizeFactor: curved,
      alignment: AlignmentDirectional.topStart,
      child: const SizedBox(height: Spaces.small),
    );
  }
}

class _AnimatedParticipantTile extends StatelessWidget {
  const _AnimatedParticipantTile({
    required this.animation,
    required this.index,
    required this.address,
    required this.onRemove,
    required this.removeLabel,
    super.key,
  });

  final Animation<double> animation;
  final int index;
  final String address;
  final VoidCallback? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final begin = Offset(
      Directionality.of(context) == TextDirection.ltr ? 32 : -32,
      0,
    );

    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: AlignmentDirectional.topStart,
        child: AnimatedBuilder(
          animation: curved,
          child: _ParticipantTile(
            index: index,
            address: address,
            onRemove: onRemove,
            removeLabel: removeLabel,
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset.lerp(begin, Offset.zero, curved.value)!,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.index,
    required this.address,
    required this.onRemove,
    required this.removeLabel,
  });

  final int index;
  final String address;
  final VoidCallback? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Spaces.extraSmall),
          child: FBadge(variant: .outline, child: Text('#${index + 1}')),
        ),
        const SizedBox(width: Spaces.small),
        Expanded(child: AddressWidget(address)),
        const SizedBox(width: Spaces.small),
        FButton.icon(
          variant: .destructive,
          onPress: onRemove,
          semanticsLabel: removeLabel,
          child: const Icon(FLucideIcons.trash2, size: 18),
        ),
      ],
    );
  }
}
