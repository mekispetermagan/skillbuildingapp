import 'package:flutter/material.dart';

Color numberColor(int number) => switch ((number - 1) % 6) {
  0 => Colors.blue.shade500,
  1 => Colors.green.shade500,
  2 => Colors.yellow.shade500,
  3 => Colors.orange.shade500,
  4 => Colors.red.shade500,
  _ => Colors.purple.shade500,
};

Color numberForeground(int number) =>
    (number - 1) % 6 == 2 ? Colors.black87 : Colors.white;
