import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mopro_flutter/mopro_types.dart';

import 'mopro_flutter_platform_interface.dart';

/// An implementation of [MoproFlutterPlatform] that uses method channels.
class MethodChannelMoproFlutter extends MoproFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mopro_flutter');

  @override
  Future<Uint8List> generateNoirProof(
      String circuitPath, String? srsPath, List<String> inputs) async {
    final result =
        await methodChannel.invokeMethod<Uint8List>('generateNoirProof', {
      'circuitPath': circuitPath,
      'srsPath': srsPath,
      'inputs': inputs,
    });
    return result ?? Uint8List(0);
  }

  @override
  Future<bool> verifyNoirProof(String circuitPath, Uint8List proof) async {
    final result = await methodChannel.invokeMethod<bool>('verifyNoirProof', {
      'circuitPath': circuitPath,
      'proof': proof,
    });
    return result ?? false;
  }
}
