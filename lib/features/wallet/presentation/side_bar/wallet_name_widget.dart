import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class WalletNameWidget extends ConsumerStatefulWidget {
  const WalletNameWidget({super.key});

  @override
  ConsumerState createState() => _WalletNameWidgetState();
}

class _WalletNameWidgetState extends ConsumerState<WalletNameWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final FocusNode _focusNode;
  bool editing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          editing = false;
        });
      }
    });
  }

  @override
  dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallets = ref.watch(walletsProvider.future);
    final walletName = ref.watch(
      walletStateProvider.select((state) => state.name),
    );
    final walletAddress = ref.watch(
      walletStateProvider.select((state) => state.address),
    );

    return Row(
      spacing: Spaces.medium,
      children: [
        FAvatar.raw(
          style: (style) =>
              style.copyWith(backgroundColor: context.theme.colors.background),
          child: HashiconWidget(hash: walletAddress, size: const Size(35, 35)),
        ),
        Expanded(
          child: FutureBuilder(
            future: wallets,
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.hasData && asyncSnapshot.data != null) {
                // Check if the wallet name is already set in the controller
                if (_nameController.text != walletName) {
                  _nameController.text = walletName;
                }

                return SizedBox(
                  width: 200, // Adjust width as needed
                  child: Form(
                    key: _formKey,
                    child: FTextFormField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      enabled: editing,
                      autocorrect: false,
                      keyboardType: TextInputType.text,
                      maxLines: 1,
                      style: context.theme.textFieldStyle
                          .copyWith(
                            contentTextStyle: FWidgetStateMap({
                              WidgetState.disabled: context.theme.typography.lg
                                  .copyWith(
                                    color: context.theme.colors.foreground,
                                  ),
                              WidgetState.any: context.theme.typography.lg
                                  .copyWith(
                                    color: context.theme.colors.primary,
                                  ),
                            }),
                          )
                          .call,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().isEmpty) {
                          return loc.field_required_error;
                        }
                        if (value.trim() != walletName &&
                            asyncSnapshot.data!.wallets.containsKey(
                              value.trim(),
                            )) {
                          return 'Wallet name already exists';
                        }
                        return null;
                      },
                      onSubmit: (value) => _onSave(value.trim()),
                    ),
                  ),
                );
              }
              // TODO: replace by shimmer
              return SizedBox.shrink();
            },
          ),
        ),
        AnimatedSwitcher(
          key: ValueKey(editing),
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: editing
              ? FTooltip(
                  tipBuilder: (context, controller) => Text(loc.save),
                  child: FButton.icon(
                    onPress: () {
                      _onSave(_nameController.text.trim());
                    },
                    child: const Icon(FIcons.check),
                  ),
                )
              : FTooltip(
                  tipBuilder: (context, controller) =>
                      Text(loc.edit_wallet_name),
                  child: FButton.icon(
                    onPress: _onEdit,
                    child: const Icon(FIcons.pencil),
                  ),
                ),
        ),
      ],
    );
  }

  void _onEdit() {
    setState(() {
      editing = !editing;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _onSave(String newName) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final walletName = ref.read(
          walletStateProvider.select((state) => state.name),
        );

        if (newName == walletName) {
          setState(() {
            editing = !editing;
          });
          return;
        }

        final walletsNotifier = ref.read(walletsProvider.notifier);
        final loc = ref.read(appLocalizationsProvider);

        await walletsNotifier.renameWallet(walletName, newName);

        ref
            .read(toastProvider.notifier)
            .showEvent(description: loc.wallet_renamed);
      } catch (e) {
        ref.read(toastProvider.notifier).showError(description: e.toString());
      }

      setState(() {
        editing = !editing;
      });
    }
  }
}
