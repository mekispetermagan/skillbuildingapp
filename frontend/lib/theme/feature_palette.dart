import 'package:flutter/material.dart';

abstract final class FeaturePalette {
  static const _seeds = <Color>[
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.purple,
  ];

  static final List<ColorScheme> _lightSchemes = List.unmodifiable([
    for (final seed in _seeds)
      ColorScheme.fromSeed(
        seedColor: seed,
        dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
      ),
  ]);

  static ColorScheme schemeForIndex(int index) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'Must not be negative');
    }
    return _lightSchemes[index % _lightSchemes.length];
  }
}
