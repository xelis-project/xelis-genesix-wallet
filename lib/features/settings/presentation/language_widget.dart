import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/languages.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_providers.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class LanguageWidget extends ConsumerStatefulWidget {
  const LanguageWidget({
    super.key,
  });

  @override
  ConsumerState createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends ConsumerState<LanguageWidget> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(languageSelectedProvider).name;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageSelectedProvider);
    return ExpansionTile(
      title: Text(
        'Language',
        style: context.titleLarge,
      ),
      subtitle: Text(
        selectedLanguage.name,
        style: context.titleMedium,
      ),
      children: List<ListTile>.generate(
        AppResources.languages.length,
        (index) => ListTile(
          title: Text(
            AppResources.languages[index],
            style: context.titleMedium,
          ),
          leading: Radio<String>(
            value: AppResources.languages[index],
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value;
              });
              if (value != null) {
                ref
                    .read(languageSelectedProvider.notifier)
                    .selectLanguage(getLanguage(value));
              }
            },
          ),
        ),
      ),
    );
    /*return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language',
                      style: context.headlineSmall,
                    ),
                    Text(
                      'English',
                      style: context.bodyMedium,
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    print('language');
                  },
                  icon: const Icon(Icons.arrow_downward_outlined),
                )
              ],
            ),
          ],
        ),
      ),
    );*/
  }
}
