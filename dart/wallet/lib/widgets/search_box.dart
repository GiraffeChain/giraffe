import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBox extends ConsumerWidget {
  const SearchBox({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    return Row(children: [
      Expanded(
          child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Search"))),
      IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            final value = controller.text;
            if (value.startsWith("b_")) {
              FluroRouter.appRouter.navigateTo(context, "/blocks/$value");
            } else if (value.startsWith("t_")) {
              FluroRouter.appRouter.navigateTo(context, "/transactions/$value");
            }
          })
    ]);
  }
}
