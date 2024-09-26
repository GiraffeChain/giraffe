import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TappableLink extends StatelessWidget {
  final Widget child;
  final String route;

  const TappableLink({super.key, required this.child, required this.route});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: child,
      ),
    );
  }
}
