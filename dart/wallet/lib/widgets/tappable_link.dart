import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class TappableLink extends StatelessWidget {
  final Widget child;
  final String route;

  const TappableLink({super.key, required this.child, required this.route});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => FluroRouter.appRouter.navigateTo(context, route),
        child: child,
      ),
    );
  }
}
