import 'package:avs_svg_provider/avs_svg_provider.dart';
import 'package:flutter/material.dart';

class GiraffeBackground extends StatelessWidget {
  final Widget child;

  const GiraffeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: _giraffeBackgroundDecoration,
      child: child,
    );
  }
}

final BoxDecoration _giraffeBackgroundDecoration = BoxDecoration(
  image: DecorationImage(
    image: AVSSVGProvider(
      "assets/images/giraffe_bottom_right.svg",
      scale: 9,
      color: const Color.fromARGB(255, 235, 224, 208),
    ),
    alignment: Alignment.bottomRight,
    fit: BoxFit.scaleDown,
  ),
  gradient: const LinearGradient(
    colors: <Color>[
      Color.fromARGB(255, 255, 241, 219),
      Color.fromARGB(255, 235, 224, 208),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
);
