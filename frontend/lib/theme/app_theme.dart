import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
    ),
  );
}
