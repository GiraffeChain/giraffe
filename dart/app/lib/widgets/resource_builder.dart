import 'package:blockchain/common/resource.dart';
import 'package:flutter/material.dart';

class ResourceBuilder<A> extends StatefulWidget {
  final Resource<A> resource;
  final AsyncWidgetBuilder<A> builder;

  const ResourceBuilder(
      {super.key, required this.resource, required this.builder});

  @override
  State<StatefulWidget> createState() => _ResourceBuilderState<A>();
}

class _ResourceBuilderState<A> extends State<ResourceBuilder<A>> {
  (A, Future<void> Function())? _allocated;
  late AsyncSnapshot<A> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<A>.waiting();
    widget.resource.allocated().then((allocated) => setState(() {
          _allocated = allocated;
          _snapshot =
              AsyncSnapshot<A>.withData(ConnectionState.active, allocated.$1);
        }));
  }

  @override
  void dispose() {
    super.dispose();
    if (_allocated != null) _allocated!.$2();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}
