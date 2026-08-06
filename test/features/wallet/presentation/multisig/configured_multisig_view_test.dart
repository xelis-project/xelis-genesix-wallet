import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/configured_multisig_view.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('renders a topoheight larger than 2^53 without intl conversion', (
    tester,
  ) async {
    final topoheight = (BigInt.one << 53) + BigInt.one;
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
        ],
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: FTheme(
            data: theme,
            child: Scaffold(
              body: ConfiguredMultisigView(
                loc: AppLocalizationsEn(),
                state: XelisWalletMultisigState(
                  threshold: 1,
                  participants: const [
                    XelisWalletMultisigParticipant(
                      id: 0,
                      address: 'xel:participant',
                    ),
                  ],
                  topoheight: topoheight,
                ),
                scrollController: ScrollController(),
                onCopyParticipant: (_) {},
                isDeleting: false,
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(formatBigInt(topoheight)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
