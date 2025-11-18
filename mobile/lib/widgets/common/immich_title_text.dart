import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';

class ImmichTitleText extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const ImmichTitleText({super.key, this.fontSize = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'rPictures',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? context.primaryColor,
        letterSpacing: -1.5,
      ),
    );
  }
}
