import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/contact_history_providers.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_grouped_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ContactDetailsScreen extends ConsumerStatefulWidget {
  final String contactAddress;

  const ContactDetailsScreen({super.key, required this.contactAddress});

  @override
  ConsumerState<ContactDetailsScreen> createState() =>
      _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends ConsumerState<ContactDetailsScreen> {
  final _notesController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isEditingNotes = false;
  bool _isEditingName = false;

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes(ContactDetails contact) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      await ref
          .read(addressBookProvider.notifier)
          .upsert(
            contact.address,
            contact.name,
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      setState(() => _isEditingNotes = false);
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showInformation(title: loc.notes_saved);
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).showError(description: e.toString());
      }
    }
  }

  Future<void> _saveName(ContactDetails contact) async {
    final loc = ref.read(appLocalizationsProvider);
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ref
          .read(toastProvider.notifier)
          .showError(description: 'Name cannot be empty');
      return;
    }
    try {
      await ref
          .read(addressBookProvider.notifier)
          .upsert(contact.address, newName, contact.note);
      setState(() => _isEditingName = false);
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showInformation(title: loc.notes_saved);
      }
    } catch (e) {
      if (mounted) {
        ref.read(toastProvider.notifier).showError(description: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final contactAsync = ref.watch(addressBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.contact_details),
        actions: [
          contactAsync.maybeWhen(
            data: (contacts) {
              final contact = contacts[widget.contactAddress];
              if (contact == null) return const SizedBox.shrink();

              return _isEditingName
                  ? Row(
                      spacing: Spaces.small,
                      children: [
                        FButton(
                          style: FButtonStyle.outline(),
                          onPress: () {
                            setState(() {
                              _isEditingName = false;
                              _nameController.text = contact.name;
                            });
                          },
                          child: Text(loc.cancel_button),
                        ),
                        FButton(
                          onPress: () => _saveName(contact),
                          child: Text(loc.save),
                        ),
                      ],
                    )
                  : FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => setState(() => _isEditingName = true),
                      prefix: const Icon(Icons.edit_rounded, size: 18),
                      child: Text(loc.edit_button),
                    );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: Spaces.small),
          FButton(
            onPress: () => TransferRoute(
              $extra: widget.contactAddress,
            ).push<void>(context),
            prefix: const Icon(Icons.send_rounded, size: 18),
            child: Text(loc.send),
          ),
          const SizedBox(width: Spaces.small),
        ],
      ),
      body: contactAsync.when(
        data: (contacts) {
          final contact = contacts[widget.contactAddress];
          if (contact == null) {
            return Center(child: Text(loc.contact_not_found));
          }

          if (_notesController.text.isEmpty && contact.note != null) {
            _notesController.text = contact.note!;
          }

          return BodyLayoutBuilder(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spaces.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spaces.medium,
                    children: [
                      _ContactInfoCard(
                        contact: contact,
                        localizations: loc,
                        nameController: _nameController,
                        isEditingName: _isEditingName,
                        onEditName: () => setState(() => _isEditingName = true),
                        onCancelName: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = contact.name;
                          });
                        },
                        onSaveName: () => _saveName(contact),
                      ),
                      _NotesCard(
                        contact: contact,
                        localizations: loc,
                        controller: _notesController,
                        isEditing: _isEditingNotes,
                        onEdit: () => setState(() => _isEditingNotes = true),
                        onCancel: () {
                          setState(() {
                            _isEditingNotes = false;
                            _notesController.text = contact.note ?? '';
                          });
                        },
                        onSave: () => _saveNotes(contact),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ContactHistoryContent(
                    contactAddress: widget.contactAddress,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: FCircularProgress()),
        error: (error, stack) => Center(child: Text('${loc.error}: $error')),
      ),
    );
  }
}

class _ContactInfoCard extends ConsumerStatefulWidget {
  final ContactDetails contact;
  final AppLocalizations localizations;
  final TextEditingController nameController;
  final bool isEditingName;
  final VoidCallback onEditName;
  final VoidCallback onCancelName;
  final VoidCallback onSaveName;

  const _ContactInfoCard({
    required this.contact,
    required this.localizations,
    required this.nameController,
    required this.isEditingName,
    required this.onEditName,
    required this.onCancelName,
    required this.onSaveName,
  });

  @override
  ConsumerState<_ContactInfoCard> createState() => _ContactInfoCardState();
}

class _ContactInfoCardState extends ConsumerState<_ContactInfoCard> {
  @override
  void initState() {
    super.initState();
    if (widget.nameController.text.isEmpty) {
      widget.nameController.text = widget.contact.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          spacing: Spaces.medium,
          children: [
            HashiconWidget(
              hash: widget.contact.address,
              size: const Size(80, 80),
            ),
            if (widget.isEditingName)
              FTextField(
                control: FTextFieldControl.managed(
                  controller: widget.nameController,
                ),
                hint: 'Contact name',
              )
            else
              Text(
                widget.contact.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate font size based on available width
                // XELIS address is typically 63 characters
                final addressLength = widget.contact.address.length;
                final availableWidth =
                    constraints.maxWidth - 80; // Account for padding and icon
                final baseCharWidth =
                    7.5; // Approximate width per character at fontSize 12
                final baseFontSize = 12.0;
                final calculatedFontSize =
                    (availableWidth /
                            (addressLength * baseCharWidth / baseFontSize))
                        .clamp(8.0, 12.0);

                return FButton(
                  style: FButtonStyle.outline(),
                  onPress: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.contact.address),
                    );
                    ref
                        .read(toastProvider.notifier)
                        .showInformation(
                          title: widget.localizations.copied_to_clipboard,
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.small,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Spaces.small,
                      children: [
                        Flexible(
                          child: Text(
                            widget.contact.address,
                            style: TextStyle(fontSize: calculatedFontSize),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.copy_rounded, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final ContactDetails contact;
  final AppLocalizations localizations;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _NotesCard({
    required this.contact,
    required this.localizations,
    required this.controller,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.small,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.notes,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isEditing)
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: onEdit,
                    prefix: const Icon(Icons.edit_rounded, size: 16),
                    child: Text(localizations.edit_button),
                  ),
              ],
            ),
            if (isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.small,
                children: [
                  FTextField(
                    control: .managed(controller: controller),
                    maxLines: 5,
                    hint: localizations.enter_notes,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: Spaces.small,
                    children: [
                      FButton(
                        style: FButtonStyle.outline(),
                        onPress: onCancel,
                        child: Text(localizations.cancel_button),
                      ),
                      FButton(onPress: onSave, child: Text(localizations.save)),
                    ],
                  ),
                ],
              )
            else
              Text(
                contact.note?.isEmpty ?? true
                    ? localizations.no_notes
                    : contact.note!,
                style: TextStyle(
                  color: contact.note?.isEmpty ?? true
                      ? context.theme.colors.mutedForeground
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactHistoryContent extends ConsumerStatefulWidget {
  final String contactAddress;

  const _ContactHistoryContent({required this.contactAddress});

  @override
  ConsumerState createState() => _ContactHistoryContentState();
}

class _ContactHistoryContentState
    extends ConsumerState<_ContactHistoryContent> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(
      contactHistoryPagingStateProvider(widget.contactAddress),
    );
    final addressBook = ref.watch(addressBookProvider);

    switch (addressBook) {
      case AsyncData(:final value):
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
          child: FadedScroll(
            controller: _controller,
            fadeFraction: 0.08,
            child:
                PagedListView<int, MapEntry<DateTime, List<TransactionEntry>>>(
                  scrollController: _controller,
                  state: pagingState,
                  fetchNextPage: _fetchPage,
                  builderDelegate:
                      PagedChildBuilderDelegate<
                        MapEntry<DateTime, List<TransactionEntry>>
                      >(
                        animateTransitions: true,
                        itemBuilder: (context, item, index) =>
                            TransactionGroupedWidget(item, value),
                        noItemsFoundIndicatorBuilder: (context) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(Spaces.large),
                            child: Text(
                              loc.no_transactions_with_contact,
                              style: context.theme.typography.base.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
          ),
        );
      case AsyncError():
        return Center(
          child: Text(
            loc.oups,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.error,
            ),
          ),
        );
      default:
        return Center(child: FCircularProgress());
    }
  }

  void _fetchPage() async {
    final state = ref.read(
      contactHistoryPagingStateProvider(widget.contactAddress),
    );

    if (state.isLoading) return;
    await Future<void>.value();
    ref
        .read(contactHistoryPagingStateProvider(widget.contactAddress).notifier)
        .loading();

    try {
      final newPage = (state.keys?.last ?? 0) + 1;
      talker.info('Fetching contact history page: $newPage');
      final transactions = await ref.read(
        contactHistoryProvider(widget.contactAddress, newPage).future,
      );

      final grouped = groupTransactionsByDateSorted2Levels(transactions);

      ref
          .read(
            contactHistoryPagingStateProvider(widget.contactAddress).notifier,
          )
          .setNextPage(newPage, grouped.entries.toList());
    } catch (error) {
      talker.error('Error fetching contact history page: $error');
      ref
          .read(
            contactHistoryPagingStateProvider(widget.contactAddress).notifier,
          )
          .error(error);
    }
  }
}
