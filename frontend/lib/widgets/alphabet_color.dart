import 'package:flutter/material.dart';

Color alphabetColor(String colorName) => switch (colorName) {
  'red' => Colors.red,
  'orange' => Colors.orange,
  'amber' => Colors.amber,
  'green' => Colors.green,
  'teal' => Colors.teal,
  'blue' => Colors.blue,
  'deepPurple' => Colors.deepPurple,
  'pink' => Colors.pink,
  'brown' => Colors.brown,
  _ => Colors.grey,
};

Color readableTextColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;
