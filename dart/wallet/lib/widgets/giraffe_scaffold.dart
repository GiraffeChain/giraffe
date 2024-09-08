import 'package:flutter/material.dart';

import 'giraffe_background.dart';

class GiraffeScaffold extends StatelessWidget {
  final String? title;
  final Widget body;

  const GiraffeScaffold({super.key, this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: title != null ? appBar(title!) : null,
      body: GiraffeBackground(
          child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.only(left: 32, right: 32, top: 8, bottom: 32),
          child: body,
        ),
      )),
    );
  }

  AppBar appBar(String title) => AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      );
}
