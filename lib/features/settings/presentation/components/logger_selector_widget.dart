import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:go_router/go_router.dart';

class LoggerSelectorWidget extends ConsumerWidget {
  const LoggerSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(
        loc.advanced_parameters,
        style: context.titleLarge,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(Spaces.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.debug_logger,
                style: context.bodyLarge,
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(AppScreen.logger.toPath),
                label: Text(
                  loc.open_button,
                  style: context.labelLarge,
                ),
                icon: Icon(
                  Icons.open_in_new,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
