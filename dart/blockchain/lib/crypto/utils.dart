import 'ed25519vrf.dart';
import 'impl/kes_product.dart';
import 'package:blockchain_sdk/sdk.dart' as sdk;

void setComputeFunction(sdk.DComputeImpl i) {
  sdk.setComputeFunction(i);
  ed25519Vrf = Ed25519VRFIsolated(sdk.isolate);
  kesProduct = KesProudctIsolated(sdk.isolate);
}
