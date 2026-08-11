import 'package:flutter/material.dart';

class FeatureLoadState extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final Widget child;

  const FeatureLoadState({
    required this.isLoading,
    required this.errorMessage,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage case final message?) {
      return Center(child: Text(message));
    }
    return child;
  }
}
