import 'package:flutter/material.dart';

import '../models/interface_language.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final ValueChanged<InterfaceLanguage> onSelect;

  const LanguageSelectionScreen({required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                    child: Text(language.nativeName),
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
