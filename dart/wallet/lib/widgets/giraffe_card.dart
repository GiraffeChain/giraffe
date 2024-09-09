import 'package:flutter/material.dart';

class GiraffeCard extends StatelessWidget {
  final Widget child;

  const GiraffeCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xCCe9e1cb),
          border: Border(
            top: BorderSide(
                width: 12, color: Color.fromARGB(255, 124, 120, 108)),
            right:
                BorderSide(width: 4, color: Color.fromARGB(255, 124, 120, 108)),
            bottom:
                BorderSide(width: 6, color: Color.fromARGB(255, 124, 120, 108)),
            left:
                BorderSide(width: 2, color: Color.fromARGB(255, 124, 120, 108)),
          ),
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(32),
              bottomLeft: Radius.circular(32))),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: child,
      ),
    );
  }
}
