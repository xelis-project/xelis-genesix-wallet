import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:go_router/go_router.dart';

class LoggerActionsBottomSheet extends StatelessWidget {
  const LoggerActionsBottomSheet({super.key, required this.actions});

  final List<LoggerActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: EdgeInsets.only(
          top: context.mediaQueryData.padding.top +
              context.mediaQueryData.viewInsets.top +
              50,
        ),
        padding: EdgeInsets.only(
          top: 20,
          bottom: context.mediaQueryData.padding.bottom,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Spaces.medium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.medium, vertical: Spaces.small)
                  .copyWith(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Logger Actions',
                    style: context.headlineSmall,
                  ),
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(
                Spaces.medium,
                Spaces.none,
                Spaces.medium,
                Spaces.medium,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(Spaces.medium),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...actions.asMap().entries.map(
                        (e) => _ActionTile(
                          action: e.value,
                          showDivider: e.key != actions.length - 1,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    this.showDivider = true,
  });

  final LoggerActionItem action;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: () => _onTap(context),
          title: Text(
            action.title,
            style: context.titleLarge,
          ),
          leading: Icon(
            action.icon,
          ),
        ),
        if (showDivider)
          Divider(
            color: context.colors.onSurface.withOpacity(0.2),
            height: 1,
          ),
      ],
    );
  }

  void _onTap(BuildContext context) {
    Navigator.pop(context);
    action.onTap();
  }
}

class LoggerActionItem {
  const LoggerActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final VoidCallback onTap;
  final String title;
  final IconData icon;
}
