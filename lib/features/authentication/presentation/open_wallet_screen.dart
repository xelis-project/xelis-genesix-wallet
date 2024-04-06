import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/components/table_generation_progress_dialog.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_dialog.dart';

class OpenWalletScreen extends ConsumerStatefulWidget {
  const OpenWalletScreen({super.key});

  @override
  ConsumerState<OpenWalletScreen> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletScreen> {
  //final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  //String? _selectedWallet;

  //late Widget _widgetOpening;

/*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_initOpenButton();
  }


  void _initOpenButton() {
    final loc = ref.read(appLocalizationsProvider);
    _widgetOpening = FilledButton(
      onPressed: _openWallet,
      child: Text(loc.open_wallet_button),
    );
  }*/

  void _showTableGenerationProgressDialog(BuildContext context) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => const TableGenerationProgressDialog(),
    );
  }

  void _openWallet(String name, String password) async {
    try {
      if (!await ref
              .read(authenticationProvider.notifier)
              .isPrecomputedTablesExists() &&
          mounted) {
        _showTableGenerationProgressDialog(context);
      } else {
        context.loaderOverlay.show();
      }

      await ref
          .read(authenticationProvider.notifier)
          .openWallet(name, password);
    } catch (e) {
      ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
              message: e.toString(),
            ),
          );
    }

    if (mounted) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final settings = ref.watch(settingsProvider);
    //final ScalableImageWidget banner = getBanner(context, settings.theme);
    final networkWallet = ref.watch(networkWalletProvider);
    //var openWallet = networkWallet.getOpenWallet(settings.network);
    var wallets = networkWallet.getWallets(settings.network);

    //_selectedWallet ??= openWallet;

    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.your_wallets,
                  style: context.headlineSmall!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.background.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ReorderableListView(
                      children: <Widget>[
                        for (var name in wallets.keys)
                          Material(
                            color: Colors.transparent,
                            key: Key(name),
                            child: InkWell(
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return PasswordDialog(
                                      onEnter: (password) {
                                        _openWallet(name, password);
                                      },
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RandomAvatar(wallets[name]!,
                                        width: 50, height: 50),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: context.headlineSmall,
                                          ),
                                          Text(
                                            truncateAddress(wallets[name]!),
                                            style: context.labelLarge!.copyWith(
                                                color: context
                                                    .moreColors.mutedColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                  ],
                                  //tileColor: _items[index].isOdd ? Colors.black : Colors.red,
                                  //title: Text('Item ${_items[index]}'),
                                ),
                              ),
                            ),
                          ),
                      ],
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          //final int item = _items.removeAt(oldIndex);
                          //_items.insert(newIndex, item);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.push(AppScreen.createWallet.toPath);
                      },
                      icon: const Icon(Icons.wallet),
                      label: Text(
                        loc.create_new_wallet,
                        style: context.titleMedium!
                            .copyWith(color: context.colors.onPrimary),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {
                        context.push(AppScreen.settings.toPath);
                      },
                      icon: const Icon(
                        Icons.settings_applications,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
    /*FormBuilder(
          key: _openFormKey,
          onChanged: () => _openFormKey.currentState!.save(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spaces.large),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        /*Row(
                          children: [
                            const Spacer(),
                            Hero(
                              tag: 'banner',
                              child: banner,
                            ),
                            const Spacer(),
                          ],
                        ),*/
                        const Spacer(),
                        Text(
                          loc.sign_in,
                          style: context.headlineLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              loc.no_wallet,
                              style: context.bodyLarge,
                            ),
                            TextButton(
                              onPressed: () {
                                context.go(
                                  AppScreen.createWallet.toPath,
                                );
                              },
                              child: Text(loc.create_wallet_button),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spaces.small),
                        DropdownMenu<String>(
                          expandedInsets: EdgeInsets.zero,
                          label: Text(
                            loc.wallet,
                            style: context.bodyLarge,
                          ),
                          requestFocusOnTap: true,
                          initialSelection: openWallet,
                          dropdownMenuEntries: wallets.entries
                              .map((entry) => DropdownMenuEntry<String>(
                                  value: entry.key, label: entry.key))
                              .toList(),
                          onSelected: (v) {
                            setState(() {
                              _selectedWallet = v;
                            });
                          },
                        ),
                        const SizedBox(height: Spaces.medium),
                        PasswordTextField(
                          textField: FormBuilderTextField(
                            name: 'password',
                            style: context.bodyLarge,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: loc.password,
                            ),
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(height: Spaces.medium),
                        TextButton.icon(
                          onPressed: _openWallet,
                          icon: Icon(Icons.login),
                          label: Text(
                            'Open',
                            style: context.titleMedium!
                                .copyWith(color: context.colors.onPrimary),
                          ),
                        ),
                        const Spacer(
                          flex: 3,
                        ),
                        OutlinedButton.icon(
                          label: const Text('Settings'),
                          icon: const Icon(
                            Icons.settings,
                            size: Spaces.medium,
                          ),
                          onPressed: () {
                            context.push(AppScreen.settings.toPath);
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),*/
  }
}
