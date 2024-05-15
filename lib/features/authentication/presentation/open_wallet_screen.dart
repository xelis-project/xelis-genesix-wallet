import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/authentication/presentation/components/table_generation_progress_dialog.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';

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
      logger.severe('Opening wallet failed: $e');
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }

    if (mounted) {
      context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    //final ScalableImageWidget banner = getBanner(context, settings.theme);

    final wallets = ref.watch(walletsProvider);

    return Background(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(Spaces.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.your_wallets,
                style: context.headlineMedium!
                    .copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: Spaces.small),
              Expanded(
                child: wallets.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(Spaces.small),
                        decoration: BoxDecoration(
                          color: context.colors.surface.withOpacity(.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ReorderableListView(
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: context.colors.surface.withOpacity(.5),
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
                                  onTap: () async {
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
                                    padding: const EdgeInsets.all(Spaces.small),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        wallets[name]!.isNotEmpty
                                            ? RandomAvatar(wallets[name]!,
                                                width: 50, height: 50)
                                            : const SizedBox(
                                                width: 50,
                                                height: 50,
                                              ),
                                        const SizedBox(width: Spaces.small),
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
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          onReorder: (int oldIndex, int newIndex) {
                            // https://api.flutter.dev/flutter/widgets/ReorderCallback.html
                            if (oldIndex < newIndex) {
                              // removing the item at oldIndex will shorten the list by 1.
                              newIndex -= 1;
                            }

                            var name = wallets.keys.elementAt(oldIndex);
                            final w = ref.read(walletsProvider.notifier);
                            w.orderWallet(name, newIndex);
                          },
                        ))
                    : Text(
                        loc.no_wallet_available,
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
    );
  }
}
