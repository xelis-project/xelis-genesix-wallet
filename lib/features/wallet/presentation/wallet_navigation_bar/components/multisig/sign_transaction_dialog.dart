import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';

class SignTransactionDialog extends ConsumerStatefulWidget {
  const SignTransactionDialog({super.key});

  @override
  ConsumerState createState() => _SignTransactionDialogState();
}

class _SignTransactionDialogState extends ConsumerState<SignTransactionDialog> {
  final _signTransactionFormKey = GlobalKey<FormState>();
  final _transactionController = TextEditingController();

  Future<String>? transactionSignature;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return AppDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  loc.sign_transaction,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(FLucideIcons.x),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: 600),
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.sign_transaction_dialog_message,
              style: context.bodyMedium!.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: Spaces.large),
            Form(
              key: _signTransactionFormKey,
              child: FTextFormField(
                control: .managed(
                  controller: _transactionController,
                  onChange: (value) {
                    if (value.text.isEmpty && transactionSignature != null) {
                      setState(() => transactionSignature = null);
                    }
                  },
                ),
                autocorrect: false,
                keyboardType: TextInputType.text,
                label: Text(loc.transaction_hash),
                clearable: (value) => value.text.isNotEmpty,
                validator: (value) {
                  final hash = value?.trim() ?? '';
                  if (hash.isEmpty) {
                    return loc.field_required_error;
                  }
                  if (hash.length != 64) {
                    return loc.sign_transaction_formfield_error;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: Spaces.large),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: FutureBuilder(
                future: transactionSignature,
                builder: (context, snapshot) {
                  if (snapshot.hasError &&
                      snapshot.connectionState != ConnectionState.none) {
                    return Column(
                      children: [
                        Text(
                          loc.error,
                          style: context.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                        Text(
                          (snapshot.error as AnyhowException).message,
                          style: context.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ],
                    );
                  } else if (snapshot.hasData &&
                      snapshot.connectionState != ConnectionState.none) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              loc.signature,
                              style: context.bodyMedium!.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                            IconButton(
                              onPressed: () => copyToClipboard(
                                snapshot.requireData,
                                ref,
                                loc.copied,
                              ),
                              icon: const Icon(FLucideIcons.copy, size: 18),
                              tooltip: loc.copy_signature,
                            ),
                          ],
                        ),
                        const SizedBox(height: Spaces.small),
                        SelectableText(snapshot.data as String),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: _signTransaction, child: Text(loc.sign))],
    );
  }

  Future<void> _signTransaction() async {
    if (_signTransactionFormKey.currentState?.validate() ?? false) {
      final future = ref
          .read(walletCommandsProvider)
          .signTransactionHash(_transactionController.text.trim());
      setState(() {
        transactionSignature = future;
      });
    }
  }
}
