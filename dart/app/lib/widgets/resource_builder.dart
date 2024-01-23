import 'package:flutter/material.dart';
import 'package:ribs_core/ribs_core.dart' hide State;

class ResourceBuilder<A> extends StatefulWidget {
  final Resource<A> resource;
  final AsyncWidgetBuilder<A> builder;

  const ResourceBuilder(
      {super.key, required this.resource, required this.builder});

  @override
  State<StatefulWidget> createState() => _ResourceBuilderState<A>();
}

class _ResourceBuilderState<A> extends State<ResourceBuilder<A>> {
  late Function() _cancel;
  late AsyncSnapshot<A> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<A>.waiting();
    _cancel = widget.resource
        .flatMap((a) => Resource.eval(IO.delay(() => setState(() {
              _snapshot = AsyncSnapshot<A>.withData(ConnectionState.active, a);
            }))))
        .useForever()
        .unsafeRunCancelable();
  }

  @override
  void dispose() {
    super.dispose();
    _cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}
