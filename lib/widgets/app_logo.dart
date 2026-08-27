import 'package:flutter/material.dart';

import '../core/constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'BuzzIt logo',
    );
  }
}
