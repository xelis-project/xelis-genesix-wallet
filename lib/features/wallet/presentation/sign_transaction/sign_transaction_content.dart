import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class SignTransactionContent extends ConsumerStatefulWidget {
  const SignTransactionContent({super.key});

  @override
  ConsumerState createState() => _SignTransactionContentState();
}

class _SignTransactionContentState
    extends ConsumerState<SignTransactionContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _transactionController = TextEditingController();

  Future<String>? transactionSignature;
  bool _submitted = false;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: Form(
        key: _formKey,
        child: Column(
          spacing: Spaces.large,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FTextFormField(
              controller: _transactionController,
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              label: Text('Transaction ID'),
              hint: 'Enter the transaction hash to sign',
              keyboardType: TextInputType.text,
              clearable: (v) => v.text.isNotEmpty,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
              onChange: (_) {
                if (_submitted) {
                  setState(() => _submitted = false);
                  _formKey.currentState?.validate();
                }
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: AppDurations.animFast),
              curve: Curves.easeOut,
              child: FCard(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 160),
                  child: Center(
                    child: FutureBuilder(
                      future: transactionSignature,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: FProgress.circularIcon());
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(Spaces.medium),
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(Spaces.medium),
                            child: SelectableText(
                              'Signature: ${snapshot.data}',
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(Spaces.medium),
                            child: Text(
                              'No signature generated yet.',
                              style: context.theme.typography.base.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            FButton(onPress: _signTransaction, child: Text('Sign Transaction')),
          ],
        ),
      ),
    );
  }

  void _signTransaction() {
    setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      final transactionHash = _transactionController.text.trim();
      final future = ref
          .read(walletStateProvider.notifier)
          .signTransactionHash(transactionHash.trim());
      setState(() {
        transactionSignature = future;
      });
    }
  }
}
