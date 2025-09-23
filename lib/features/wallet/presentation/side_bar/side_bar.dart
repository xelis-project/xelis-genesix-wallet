import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/presentation/side_bar/side_bar_footer.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  late String _selectedItem;

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

    _selectedItem = context.goRouterState.fullPath ?? AuthAppScreen.home.toPath;

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
              selected: _selectedItem == AuthAppScreen.home.toPath,
              icon: const Icon(FIcons.house),
              label: const Text('Home'),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.home.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.home.toPath;
                });
              },
            ),
            FSidebarItem(
              icon: const Icon(FIcons.wallet),
              label: const Text('Wallet'),
              initiallyExpanded: false,
              children: [
                FSidebarItem(
                  selected:
                      _selectedItem == AuthAppScreen.signTransaction.toPath,
                  label: Text('Sign Transaction'),
                  onPress: () {
                    _closeSideBar();
                    context.go(AuthAppScreen.signTransaction.toPath);
                    setState(() {
                      _selectedItem = AuthAppScreen.signTransaction.toPath;
                    });
                  },
                ),
                FSidebarItem(
                  selected: _selectedItem == AuthAppScreen.multisig.toPath,
                  label: Text('Multisig Management'),
                  onPress: () {
                    _closeSideBar();
                    context.go(AuthAppScreen.multisig.toPath);
                    setState(() {
                      _selectedItem = AuthAppScreen.multisig.toPath;
                    });
                  },
                ),
                FSidebarItem(
                  selected: _selectedItem == AuthAppScreen.xswd.toPath,
                  label: const Text('XSWD Protocol'),
                  onPress: xswdEnabled
                      ? () {
                          _closeSideBar();
                          context.go(AuthAppScreen.xswd.toPath);
                          setState(() {
                            _selectedItem = AuthAppScreen.xswd.toPath;
                          });
                        }
                      : null,
                ),
                FSidebarItem(
                  selected: _selectedItem == 'Burn Transfer',
                  label: Text('Burn Transfer'),
                  onPress: burnTransferEnabled
                      ? () {
                          _closeSideBar();
                          // TODO: Implement burn transfer management
                          print('Burn pressed');
                          setState(() {
                            _selectedItem = 'Burn Transfer';
                          });
                        }
                      : null,
                ),
              ],
            ),
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.network.toPath,
              label: Text(loc.network),
              icon: const Icon(FIcons.waypoints),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.network.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.network.toPath;
                });
              },
            ),
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.addressBook.toPath,
              label: Text(loc.address_book.capitalizeAll()),
              icon: const Icon(FIcons.bookUser),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.addressBook.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.addressBook.toPath;
                });
              },
            ),
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.history.toPath,
              label: Text(loc.history),
              icon: const Icon(FIcons.history),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.history.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.history.toPath;
                });
              },
            ),
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.assets.toPath,
              label: Text('Assets'),
              icon: const Icon(FIcons.landmark),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.assets.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.assets.toPath;
                });
              },
            ),
          ],
        ),
        FSidebarGroup(
          label: const Text('Account'),
          children: [
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.recoveryPhrase.toPath,
              icon: const Icon(FIcons.key),
              label: Text(loc.recovery_phrase),
              onPress: () {
                _closeSideBar();

                if (context.goRouterState.fullPath ==
                    AuthAppScreen.recoveryPhrase.toPath) {
                  return;
                }

                startWithBiometricAuth(
                  ref,
                  callback: (ref) {
                    context.go(AuthAppScreen.recoveryPhrase.toPath);
                    setState(() {
                      _selectedItem = AuthAppScreen.recoveryPhrase.toPath;
                    });
                  },
                  reason: 'Please authenticate to view your recovery phrase',
                );
              },
            ),
            FSidebarItem(
              selected: _selectedItem == AuthAppScreen.settings.toPath,
              icon: const Icon(FIcons.settings),
              label: Text(loc.settings),
              onPress: () {
                _closeSideBar();
                context.go(AuthAppScreen.settings.toPath);
                setState(() {
                  _selectedItem = AuthAppScreen.settings.toPath;
                });
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
