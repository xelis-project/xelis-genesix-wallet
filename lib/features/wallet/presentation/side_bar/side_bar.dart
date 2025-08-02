import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/presentation/side_bar/side_bar_footer.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final xswdEnabled = ref.watch(
      settingsProvider.select((state) => state.enableXswd),
    );
    final burnTransferEnabled = ref.watch(
      settingsProvider.select((state) => state.unlockBurn),
    );
    final appTheme = ref.watch(
      settingsProvider.select((state) => state.appTheme),
    );

    final isDarkMode = appTheme == AppTheme.dark || appTheme == AppTheme.xelis;

    return FSidebar(
      header: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          children: [
            Hero(
              tag: 'genesix-logo',
              child: ScalableImageWidget(
                scale: 0.8,
                si: isDarkMode
                    ? AppResources.svgGenesixWalletOneLineWhite
                    : AppResources.svgGenesixWalletOneLineBlack,
              ),
            ),
            const SizedBox(height: Spaces.medium),
            FDivider(
              style: context.theme.dividerStyles.horizontalStyle
                  .copyWith(padding: EdgeInsets.zero)
                  .call,
            ),
          ],
        ),
      ),
      footer: SideBarFooter(),
      children: [
        FSidebarGroup(
          label: const Text('Overview'),
          children: [
            FSidebarItem(
              icon: const Icon(FIcons.house),
              label: const Text('Home'),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.home.toPath);
              },
            ),
            FSidebarItem(
              icon: const Icon(FIcons.wallet),
              label: const Text('Wallet'),
              initiallyExpanded: false,
              children: [
                FSidebarItem(
                  label: Text('Sign Transaction'),
                  onPress: () {
                    _closeSideBar();
                    // TODO: Implement sign transaction management
                    print('sign pressed');
                  },
                ),
                FSidebarItem(
                  label: Text('Multisig Management'),
                  onPress: () {
                    _closeSideBar();
                    // TODO: Implement multisig management
                    print('Multisig pressed');
                  },
                ),
                FSidebarItem(
                  label: const Text('XSWD Protocol'),
                  onPress: xswdEnabled
                      ? () {
                          _closeSideBar();
                          // TODO: Implement XSWD protocol management
                          print('XSWD pressed');
                        }
                      : null,
                ),
                FSidebarItem(
                  label: Text('Burn Transfer'),
                  onPress: burnTransferEnabled
                      ? () {
                          _closeSideBar();
                          // TODO: Implement burn transfer management
                          print('Burn pressed');
                        }
                      : null,
                ),
              ],
            ),
            FSidebarItem(
              label: Text(loc.network),
              icon: const Icon(FIcons.waypoints),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.network.toPath);
              },
            ),
            FSidebarItem(
              label: Text(loc.address_book.capitalizeAll()),
              icon: const Icon(FIcons.bookUser),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.addressBook.toPath);
              },
            ),
            FSidebarItem(
              label: Text(loc.history),
              icon: const Icon(FIcons.history),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.history.toPath);
              },
            ),
            FSidebarItem(
              label: Text('Assets'),
              icon: const Icon(FIcons.landmark),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.assets.toPath);
              },
            ),
          ],
        ),
        FSidebarGroup(
          label: const Text('Account'),
          children: [
            FSidebarItem(
              icon: const Icon(FIcons.key),
              label: Text(loc.recovery_phrase),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.recoveryPhrase.toPath);
              },
            ),
            FSidebarItem(
              icon: const Icon(FIcons.settings),
              label: Text(loc.settings),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.settings.toPath);
              },
            ),
            FSidebarItem(
              icon: const Icon(FIcons.logOut),
              label: Text(loc.logout),
              onPress: () => ref.read(authenticationProvider.notifier).logout(),
            ),
          ],
        ),
      ],
    );
  }

  void _closeSideBar() {
    if (context.mounted && context.canPop()) {
      context.pop();
    }
  }
}
