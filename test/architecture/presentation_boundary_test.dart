import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation and Flame renderers do not import controllers', () {
    const presentationDirectories = ['lib/screens', 'lib/widgets', 'lib/games'];
    final violations = <String>[];

    for (final directoryPath in presentationDirectories) {
      final files = Directory(directoryPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in files) {
        if (RegExp(
          r'''import\s+['"][^'"]*controllers/''',
        ).hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature controllers are private to SessionController; '
          'presentation receives ViewData and callbacks.',
    );
  });
}
