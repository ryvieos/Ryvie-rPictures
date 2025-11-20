import 'package:flutter/material.dart';

class ImmichLogo extends StatelessWidget {
  final double size;
  final dynamic heroTag;

  const ImmichLogo({super.key, this.size = 100, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/rpictures-logo.png',
      width: size,
      height: size,
    );
  }
}
