import 'dart:typed_data';

import 'package:convert/convert.dart';

extension StringOps on String {
  Uint8List get hexStringToBytes => (hex.decode(this) as Uint8List);
}
