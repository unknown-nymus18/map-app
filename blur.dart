import 'dart:ui';

import 'package:flutter/material.dart';

class Blur extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final BorderRadiusGeometry? borderRadius;
  const Blur({
    super.key,
    required this.child,
    required this.sigmaX,
    required this.sigmaY,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(),
        Center(
          child: ClipRRect(
            borderRadius: borderRadius ?? const BorderRadius.all(Radius.zero),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaX),
              child: child,
            ),
          ),
        )
      ],
    );
  }
}
