import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';

class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.contact,
    required this.localizations,
    this.onOpen,
    this.onSend,
    this.onEdit,
    this.onDelete,
  });

  final ContactDetails contact;
  final AppLocalizations localizations;
  final VoidCallback? onOpen;
  final VoidCallback? onSend;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return FItem.raw(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showActions =
              onSend != null || onEdit != null || onDelete != null;
          final compact = constraints.maxWidth < context.theme.breakpoints.sm;
          final identity = _ContactIdentityButton(
            contact: contact,
            onOpen: onOpen,
            compact: compact,
          );
          final actions = _ContactActions(
            localizations: localizations,
            name: contact.name,
            compact: compact,
            onSend: onSend,
            onEdit: onEdit,
            onDelete: onDelete,
          );

          return Row(
            children: [
              Expanded(child: identity),
              if (showActions) ...[
                const SizedBox(width: Spaces.small),
                actions,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ContactIdentityButton extends StatefulWidget {
  const _ContactIdentityButton({
    required this.contact,
    required this.onOpen,
    required this.compact,
  });

  final ContactDetails contact;
  final VoidCallback? onOpen;
  final bool compact;

  @override
  State<_ContactIdentityButton> createState() => _ContactIdentityButtonState();
}

class _ContactIdentityButtonState extends State<_ContactIdentityButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed
        ? context.theme.colors.muted.withValues(alpha: 0.55)
        : _hovered
        ? context.theme.colors.muted.withValues(alpha: 0.35)
        : const Color(0x00000000);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spaces.extraSmall,
        vertical: Spaces.small,
      ),
      child: Row(
        children: [
          HashiconWidget(
            hash: widget.contact.address,
            size: Size(widget.compact ? 32 : 38, widget.compact ? 32 : 38),
          ),
          const SizedBox(width: Spaces.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spaces.extraSmall,
              children: [
                Text(
                  widget.contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  truncateText(
                    widget.contact.address,
                    maxLength: widget.compact ? 18 : 28,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                if (widget.contact.note?.isNotEmpty ?? false)
                  Text(
                    widget.contact.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onOpen != null) ...[
            const SizedBox(width: Spaces.small),
            Icon(
              FLucideIcons.chevronRight,
              size: 18,
              color: context.theme.colors.mutedForeground,
            ),
          ],
        ],
      ),
    );

    final decoratedContent = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );

    if (widget.onOpen == null) return decoratedContent;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          },
          child: decoratedContent,
        ),
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({
    required this.localizations,
    required this.name,
    required this.compact,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
  });

  final AppLocalizations localizations;
  final String name;
  final bool compact;
  final VoidCallback? onSend;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spaces.extraSmall,
      children: [
        if (onSend != null)
          FTooltip(
            tipBuilder: (_, _) => Text(localizations.transfer_to_contact(name)),
            child: FButton.icon(
              onPress: onSend,
              child: Icon(
                FLucideIcons.send,
                color: context.theme.colors.primary,
                size: 18,
              ),
            ),
          ),
        if (compact) ...[
          if (onEdit != null || onDelete != null)
            FPopoverMenu(
              semanticsLabel: localizations.more_actions,
              menuAnchor: Alignment.topRight,
              childAnchor: Alignment.bottomRight,
              menu: [
                FItemGroup(
                  children: [
                    if (onEdit != null)
                      FItem(
                        prefix: const Icon(FLucideIcons.pencil, size: 18),
                        title: Text(localizations.edit_contact),
                        onPress: onEdit,
                      ),
                    if (onDelete != null)
                      FItem(
                        variant: .destructive,
                        prefix: const Icon(FLucideIcons.trash, size: 18),
                        title: Text(localizations.remove_contact),
                        onPress: onDelete,
                      ),
                  ],
                ),
              ],
              builder: (_, controller, _) => FTooltip(
                tipBuilder: (_, _) => Text(localizations.more_actions),
                child: FButton.icon(
                  semanticsLabel: localizations.more_actions,
                  onPress: controller.toggle,
                  child: const Icon(FLucideIcons.ellipsis, size: 18),
                ),
              ),
            ),
        ] else ...[
          if (onEdit != null)
            FTooltip(
              tipBuilder: (_, _) => Text(localizations.edit_contact),
              child: FButton.icon(
                onPress: onEdit,
                child: const Icon(FLucideIcons.pencil, size: 18),
              ),
            ),
          if (onDelete != null)
            FTooltip(
              tipBuilder: (_, _) => Text(localizations.remove_contact),
              child: FButton.icon(
                onPress: onDelete,
                child: Icon(
                  FLucideIcons.trash,
                  color: context.theme.colors.destructive,
                  size: 18,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
