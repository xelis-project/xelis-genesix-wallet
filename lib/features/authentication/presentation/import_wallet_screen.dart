import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/presentation/components/private_key_tab.dart';
import 'package:genesix/features/authentication/presentation/components/recovery_phrase_tab.dart';
import 'package:genesix/features/authentication/presentation/components/restore_folder_tab.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';

class ImportWalletScreen extends ConsumerWidget {
  ImportWalletScreen({super.key});

  final _controller = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return FScaffold(
      header: FHeader.nested(
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.back(onPress: context.pop),
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
                child: Center(
                  child: Container(
                    width: context.mediaWidth * 0.9,
                    constraints: BoxConstraints(
                      maxWidth: context.theme.breakpoints.sm,
                      minHeight: 600,
                    ),
                    child: FTabs(
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
                            label: const Text(
                              'Restore Folder',
                              textAlign: TextAlign.center,
                            ),
                            child: RestoreFolderTab(),
                          ),
                      ],
                    ),
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
