import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LayeredPerson extends StatelessWidget {
  final String shirtImagePath;
  final String jeansImagePath;
  final double width;
  final double height;

  const LayeredPerson({
    required this.shirtImagePath,
    required this.jeansImagePath,
    this.width = 144,
    this.height = 240,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            jeansImagePath,
            key: const ValueKey('jeans-image'),
            fit: BoxFit.contain,
          ),
          SvgPicture.asset(
            shirtImagePath,
            key: const ValueKey('shirt-image'),
            fit: BoxFit.contain,
          ),
        ],
      ),
    ),
  );
}
