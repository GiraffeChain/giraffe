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
    image: AVSSVGProvider("assets/images/giraffe_bottom_right.svg",
        scale: 9,
        gradient: const LinearGradient(
          colors: <Color>[
            Color.fromARGB(255, 102, 62, 3),
            Color.fromARGB(255, 66, 4, 75)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
    alignment: Alignment.bottomRight,
    fit: BoxFit.scaleDown,
  ),
  color: const Color(0xFFe9e1cb),
);
