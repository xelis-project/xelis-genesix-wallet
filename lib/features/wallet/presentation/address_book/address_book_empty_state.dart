import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

enum _AddressBookEmptyStateType { noContacts, noSearchResults }

class AddressBookEmptyState extends StatelessWidget {
  const AddressBookEmptyState.noContacts({
    super.key,
    required this.localizations,
    this.onAddContact,
    this.compact = false,
  }) : _type = _AddressBookEmptyStateType.noContacts;

  const AddressBookEmptyState.noSearchResults({
    super.key,
    required this.localizations,
    this.compact = false,
  }) : _type = _AddressBookEmptyStateType.noSearchResults,
       onAddContact = null;

  final AppLocalizations localizations;
  final VoidCallback? onAddContact;
  final bool compact;
  final _AddressBookEmptyStateType _type;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = EdgeInsets.all(compact ? Spaces.medium : Spaces.large);
        final fullWidthAction = context.isMobile;
        final content = _EmptyStateContent(
          title: switch (_type) {
            _AddressBookEmptyStateType.noContacts =>
              localizations.no_contacts_yet,
            _AddressBookEmptyStateType.noSearchResults =>
              localizations.no_contact_found,
          },
          message: switch (_type) {
            _AddressBookEmptyStateType.noContacts =>
              localizations.address_book_empty,
            _AddressBookEmptyStateType.noSearchResults =>
              localizations.try_changing_filter,
          },
          icon: switch (_type) {
            _AddressBookEmptyStateType.noContacts => FLucideIcons.users,
            _AddressBookEmptyStateType.noSearchResults => FLucideIcons.search,
          },
          actionLabel: onAddContact == null ? null : localizations.add_contact,
          onAction: onAddContact,
          compact: compact,
          fullWidthAction: fullWidthAction,
        );

        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }

        final minHeight = (constraints.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

class _EmptyStateContent extends StatelessWidget {
  const _EmptyStateContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.compact,
    required this.fullWidthAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool fullWidthAction;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 48.0 : 64.0;
    final iconSize = compact ? 22.0 : 28.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 320 : 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: compact ? Spaces.small : Spaces.medium,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.theme.colors.muted,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: iconBoxSize,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: context.theme.colors.primary,
                ),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? context.theme.typography.body.md
                        : context.theme.typography.body.lg)
                    .copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? Spaces.extraSmall : Spaces.small),
            if (fullWidthAction)
              FButton(
                onPress: onAction,
                prefix: const Icon(FLucideIcons.plus, size: 16),
                child: Text(actionLabel!),
              )
            else
              Center(
                child: FButton(
                  onPress: onAction,
                  prefix: const Icon(FLucideIcons.plus, size: 16),
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
