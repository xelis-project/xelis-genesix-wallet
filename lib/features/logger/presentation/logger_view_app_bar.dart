import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/presentation/logger_view_controller.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:group_button/group_button.dart';

class LoggerViewAppBar extends ConsumerWidget {
  const LoggerViewAppBar({
    super.key,
    required this.titlesController,
    required this.controller,
    required this.titles,
    required this.uniqueTitles,
    required this.onActionsTap,
    required this.onToggleTitle,
  });

  final GroupButtonController titlesController;
  final LoggerViewController controller;

  final List<String?> titles;
  final List<String?> uniqueTitles;

  final VoidCallback onActionsTap;

  final void Function(String title, bool selected) onToggleTitle;

  void _onToggle(String? title, bool selected) {
    if (title == null) return;
    onToggleTitle(title, selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return SliverAppBar(
      backgroundColor: context.colors.surface,
      // elevation:0,
      pinned: true,
      floating: true,
      expandedHeight: 174,
      collapsedHeight: 60,
      toolbarHeight: 60,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spaces.small,
          Spaces.medium,
          Spaces.none,
          Spaces.none,
        ),
        child: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spaces.none,
            Spaces.medium,
            Spaces.small,
            Spaces.none,
          ),
          child: UnconstrainedBox(
            child: IconButton(
              onPressed: onActionsTap,
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      title: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spaces.none,
          Spaces.medium,
          Spaces.none,
          Spaces.none,
        ),
        child: Text(
          loc.logger,
          style: context.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.medium,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: [
                      GroupButton(
                        controller: titlesController,
                        isRadio: false,
                        buttonBuilder: (selected, value, context) {
                          final count = titles.where((e) => e == value).length;
                          return Container(
                            padding: const EdgeInsets.all(Spaces.small),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.colors.onSurface,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              color: selected
                                  ? context.colors.primaryContainer
                                  : context.colors.surfaceContainer,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$count',
                                  style: selected
                                      ? context.bodySmall?.copyWith(
                                          color: context.colors.onPrimary,
                                        )
                                      : context.bodySmall,
                                ),
                                const SizedBox(width: Spaces.extraSmall),
                                Text(
                                  '$value',
                                  style: selected
                                      ? context.bodySmall?.copyWith(
                                          color: context.colors.onPrimary,
                                        )
                                      : context.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                        onSelected: (_, i, selected) =>
                            _onToggle(uniqueTitles[i], selected),
                        buttons: uniqueTitles,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                _SearchTextField(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchTextField extends ConsumerWidget {
  const _SearchTextField({required this.controller});

  final LoggerViewController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
      child: TextFormField(
        style: context.bodyLarge,
        onChanged: controller.updateFilterSearchQuery,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colors.onSurface),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: context.colors.onSurface),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: Spaces.medium),
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: '${loc.search} ...',
          hintStyle: context.bodyLarge,
        ),
      ),
    );
  }
}
