import 'dart:io';

import 'package:blockchain/codecs.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

void main() async {
  final bytes = File(
          "/home/sean/Documents/blockchain/genesis-init/b_Z3PtvCM6nqfZ4UwgA3Ltv6z7agMeHXhtp7Dn3BtFEjz/genesis/b_Z3PtvCM6nqfZ4UwgA3Ltv6z7agMeHXhtp7Dn3BtFEjz/t_52wAQkoKYsjdkJxgBkAEbkscrx26cLwiEiX2868vLAFi.transaction.pbuf")
      .readAsBytesSync();
  final tx = Transaction.fromBuffer(bytes);
  print(tx.immutableBytes.base58);
}
