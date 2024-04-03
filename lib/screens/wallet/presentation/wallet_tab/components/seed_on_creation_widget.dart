import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/wallet_tab/components/seed_content_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class SeedOnCreationWidget extends ConsumerStatefulWidget {
  const SeedOnCreationWidget(this.password, {super.key});

  final String password;

  @override
  ConsumerState<SeedOnCreationWidget> createState() =>
      _SeedOnCreationWidgetState();
}

class _SeedOnCreationWidgetState extends ConsumerState<SeedOnCreationWidget> {
  Future<String?>? _pendingSeed;

  @override
  void initState() {
    super.initState();
    final wallet = ref.read(walletStateProvider);
    _pendingSeed = wallet.nativeWalletRepository!.getSeed();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc.my_seed,
        style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Builder(builder: (context) {
        final width = context.mediaSize.width * 0.8;

        return SizedBox(
          width: isDesktopDevice ? width : null,
          child: FutureBuilder(
            future: _pendingSeed,
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  if (snapshot.hasData) {
                    return SeedContentWidget(snapshot.requireData);
                  } else {
                    return Text(loc.oups);
                  }
              }
            },
          ),
        );
      }),
      actions: [
        FilledButton(onPressed: () => context.pop(), child: Text(loc.ok_button))
      ],
    );
  }
}
