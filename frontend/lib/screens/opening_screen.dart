import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class OpeningScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OpeningScreen({required this.onStart, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Skill Building Games",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight(500)),
            ),
            Image(
              image: AssetImage("assets/images/opening_image.png"),
              width: 300,
            ),
            FilledButton(
              onPressed: onStart,
              child: Padding(
                padding: const EdgeInsets.all(9.0),
                child: Text(context.l10n.start, style: TextStyle(fontSize: 30)),
              ),
            ),
            Image(
              image: AssetImage(
                "assets/images/ag_uganda_no_slogan_thick_dark_no_bg_hq.png",
              ),
              width: 300,
            ),
          ],
        ),
      ),
    ),
  );
}
