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
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spaces.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.your_wallets,
                  style: context.headlineMedium!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: wallets.isNotEmpty
                        ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.background.withOpacity(.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ReorderableListView(
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color:
                                    context.colors.background.withOpacity(.5),
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                child: child,
                              );
                            },
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  truncateAddress(
                                                      wallets[name]!),
                                                  style: context.labelLarge!
                                                      .copyWith(
                                                          color: context
                                                              .moreColors
                                                              .mutedColor),
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
                          )
                        
                  ): Text(
                            'You don\'t have any wallets available. Create a new wallet from the button below or make sure the app is set the desired network configuration.',
                            style: context.bodyLarge!.copyWith(
                              color: context.moreColors.mutedColor,
                              fontSize: 18,
                            ),
                          ),
                ),
                const SizedBox(height: Spaces.large),
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
  }
}
