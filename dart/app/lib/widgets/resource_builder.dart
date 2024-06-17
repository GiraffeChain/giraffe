import 'package:blockchain/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:ribs_effect/ribs_effect.dart';

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
    final (result, cancelF) = widget.resource
        .flatMap((a) => Resource.eval(IO.delay(() => setState(() {
              _snapshot = AsyncSnapshot<A>.withData(ConnectionState.active, a);
            }))))
        .useForever()
        .onError((a) => IO
            .delay(() => setState(() {
                  _snapshot =
                      AsyncSnapshot<A>.withError(ConnectionState.done, a);
                }))
            .voided())
        .unsafeRunFutureCancelable();
    result.then((_) => unit).onError<Object>((error, stackTrace) {
      error != "Fiber canceled"
          ? setState(() => _snapshot = AsyncSnapshot<A>.withError(
              ConnectionState.done, error, stackTrace))
          : ();
      return unit;
    }).ignore();
    _cancel = cancelF;
  }

  @override
  void dispose() {
    super.dispose();
    _cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}
