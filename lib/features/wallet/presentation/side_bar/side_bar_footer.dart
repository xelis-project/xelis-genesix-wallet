import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/side_bar/account_sheet.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class SideBarFooter extends ConsumerStatefulWidget {
  const SideBarFooter({super.key});

  @override
  ConsumerState createState() => _SideBarFooterState();
}

class _SideBarFooterState extends ConsumerState<SideBarFooter> {
  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletStateProvider);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: showAccountSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
          child: FCard.raw(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                spacing: 10,
                children: [
                  FAvatar.raw(
                    style: .delta(
                      backgroundColor: context.theme.colors.background,
                    ),
                    child: HashiconWidget(
                      hash: walletState.address,
                      size: const Size(25, 25),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          walletState.name,
                          style: context.theme.typography.sm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.theme.colors.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          truncateText(walletState.address, maxLength: 16),
                          style: context.theme.typography.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAccountSheet() {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => AccountSheet(),
    );
  }
}
