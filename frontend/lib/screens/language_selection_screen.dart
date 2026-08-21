import 'package:flutter/material.dart';

import '../models/interface_language.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final ValueChanged<InterfaceLanguage> onSelect;
  final InterfaceLanguage selectedLanguage;
  final VoidCallback onBack;

  const LanguageSelectionScreen({
    required this.onSelect,
    required this.selectedLanguage,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Change language'),
      leading: BackButton(onPressed: onBack),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final language in InterfaceLanguage.values) ...[
                  FilledButton(
                    key: ValueKey('language-${language.name}'),
                    onPressed: () => onSelect(language),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 22),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (language == selectedLanguage) ...[
                          const Icon(Icons.check),
                          const SizedBox(width: 8),
                        ],
                        Text(language.nativeName),
                      ],
                    ),
                  ),
                  if (language != InterfaceLanguage.values.last)
                    const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
