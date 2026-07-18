import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/presentation/components/current_network_indicator.dart';
import 'package:genesix/features/authentication/presentation/components/private_key_tab.dart';
import 'package:genesix/features/authentication/presentation/components/recovery_phrase_tab.dart';
import 'package:genesix/features/authentication/presentation/components/restore_folder_tab.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';

class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return FScaffold(
      header: FHeader.nested(
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.back(onPress: context.pop),
          ),
        ],
        suffixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: Icon(FLucideIcons.settings),
              onPress: () => context.push(AppScreen.lightSettings.toPath),
            ),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FadedScroll(
            controller: _controller,
            fadeFraction: 0.08,
            child: SingleChildScrollView(
              controller: _controller,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  width: context.viewportWidth * 0.9,
                  constraints: BoxConstraints(
                    maxWidth: context.theme.breakpoints.sm,
                    minHeight: 600,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AuthenticationStatusIndicators(),
                      const SizedBox(height: Spaces.medium),
                      FTabs(
                        children: [
                          FTabEntry(
                            label: Text(
                              loc.recovery_phrase,
                              textAlign: TextAlign.center,
                            ),
                            child: RecoveryPhraseTab(),
                          ),
                          FTabEntry(
                            label: Text(
                              loc.private_key.capitalizeAll(),
                              textAlign: TextAlign.center,
                            ),
                            child: PrivateKeyTab(),
                          ),
                          if (isDesktopDevice)
                            FTabEntry(
                              label: Text(
                                loc.restore_folder,
                                textAlign: TextAlign.center,
                              ),
                              child: RestoreFolderTab(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
