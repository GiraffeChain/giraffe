import 'package:flutter/material.dart';

extension WidgetPadOps on Widget {
  Widget get pad8 => Padding(padding: const EdgeInsets.all(8), child: this);
  Widget get pad16 => Padding(padding: const EdgeInsets.all(16), child: this);
}
