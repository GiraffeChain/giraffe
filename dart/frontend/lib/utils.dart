import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

extension WidgetPadOps on Widget {
  Widget pad(double amount) =>
      Padding(padding: EdgeInsets.all(amount), child: this);
  Widget get pad8 => Padding(padding: const EdgeInsets.all(8), child: this);
  Widget get pad16 => Padding(padding: const EdgeInsets.all(16), child: this);
}

extension WidgetsPadOps on Iterable<Widget> {
  List<Widget> get padAll8 => map((e) => e.pad8).toList();
  List<Widget> get padAll16 => map((e) => e.pad16).toList();
  List<Widget> padAll(double amount) => map((e) => e.pad(amount)).toList();
}

bool get isAndroidSafe {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid;
}
