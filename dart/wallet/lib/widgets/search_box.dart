import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        onPressed: () => handleQuery(context, controller.text),
      ),
    ]);
  }

  void handleQuery(BuildContext context, String value) {
    if (value.startsWith("b_")) {
      context.push("/blocks/$value");
    } else if (value.startsWith("t_")) {
      context.push("/transactions/$value");
    } else if (value.startsWith("a_")) {
      context.push("/addresses/$value");
    }
  }
}
