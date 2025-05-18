import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/logger/presentation/logger_actions_bottom_sheet.dart';
import 'package:genesix/features/logger/presentation/logger_view_app_bar.dart';
import 'package:genesix/features/logger/presentation/logger_view_controller.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:group_button/group_button.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggerView extends ConsumerStatefulWidget {
  const LoggerView({super.key, required this.talker, required this.theme});

  final Talker talker;
  final TalkerScreenTheme theme;

  @override
  ConsumerState<LoggerView> createState() => _LoggerViewState();
}

class _LoggerViewState extends ConsumerState<LoggerView> {
  final _titlesController = GroupButtonController();
  final _controller = LoggerViewController();

  TalkerData _getListItem(List<TalkerData> filteredElements, int i) {
    final data =
        filteredElements[_controller.isLogOrderReversed
            ? filteredElements.length - 1 - i
            : i];
    return data;
  }

  void _onToggleTitle(String title, bool selected) {
    if (selected) {
      _controller.addFilterTitle(title);
    } else {
      _controller.removeFilterTitle(title);
    }
  }

  void _copyLoggerDataItemText(TalkerData data) {
    final loc = ref.read(appLocalizationsProvider);
    final text = data.generateTextMessage(
      timeFormat: widget.talker.settings.timeFormat,
    );
    Clipboard.setData(ClipboardData(text: text));
    ref.read(snackBarQueueProvider.notifier).showInfo(loc.copied);
  }

  void _copyAllLogs(BuildContext context) {
    final loc = ref.read(appLocalizationsProvider);
    Clipboard.setData(
      ClipboardData(
        text: widget.talker.history.text(
          timeFormat: widget.talker.settings.timeFormat,
        ),
      ),
    );
    ref.read(snackBarQueueProvider.notifier).showInfo(loc.all_logs_copied);
  }

  Future<void> _showActionsBottomSheet(BuildContext context) async {
    final loc = ref.read(appLocalizationsProvider);
    await showModalBottomSheet<LoggerActionsBottomSheet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return LoggerActionsBottomSheet(
          actions: [
            LoggerActionItem(
              onTap: _controller.toggleLogOrder,
              title: loc.reverse_logs,
              icon: Icons.swap_vert,
            ),
            LoggerActionItem(
              onTap: () => _copyAllLogs(context),
              title: loc.copy_all_logs,
              icon: Icons.copy,
            ),
            LoggerActionItem(
              onTap: _cleanHistory,
              title: loc.clean_history,
              icon: Icons.delete_outline,
            ),
            // TalkerActionItem(
            //   onTap: _shareLogsInFile,
            //   title: 'Share logs file',
            //   icon: Icons.ios_share_outlined,
            // ),
          ],
        );
      },
    );
  }

  void _cleanHistory() {
    widget.talker.cleanHistory();
    _controller.update();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return TalkerBuilder(
            talker: widget.talker,
            builder: (context, data) {
              final filteredElements =
                  data.where((e) => _controller.filter.filter(e)).toList();
              final titles = data.map((e) => e.title).toList();
              final uniqueTitles = titles.toSet().toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  LoggerViewAppBar(
                    titlesController: _titlesController,
                    controller: _controller,
                    titles: titles,
                    uniqueTitles: uniqueTitles,
                    onActionsTap: () => _showActionsBottomSheet(context),
                    onToggleTitle: _onToggleTitle,
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Spaces.small),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final data = _getListItem(filteredElements, index);
                      return TalkerDataCard(
                        data: data,
                        onCopyTap: () => _copyLoggerDataItemText(data),
                        color: data.getColor(widget.theme),
                      );
                    }, childCount: filteredElements.length),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
