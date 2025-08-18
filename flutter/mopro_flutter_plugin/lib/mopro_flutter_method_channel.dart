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
  Future<Uint8List> generateNoirKeccakProofWithVk(
      String circuitPath, String? srsPath, Uint8List vk, List<String> inputs, 
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    final result =
        await methodChannel.invokeMethod<Uint8List>('generateNoirKeccakProofWithVk', {
      'circuitPath': circuitPath,
      'srsPath': srsPath,
      'vk': vk,
      'inputs': inputs,
      'disableZk': disableZk,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? Uint8List(0);
  }

  @override
  Future<bool> verifyNoirKeccakProofWithVk(String circuitPath, Uint8List vk, Uint8List proof,
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    final result = await methodChannel.invokeMethod<bool>('verifyNoirKeccakProofWithVk', {
      'circuitPath': circuitPath,
      'vk': vk,
      'proof': proof,
      'disableZk': disableZk,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? false;
  }

  @override
  Future<Uint8List> getNoirVerificationKeccakKey(String circuitPath, String? srsPath,
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    final result = await methodChannel.invokeMethod<Uint8List>('getNoirVerificationKeccakKey', {
      'circuitPath': circuitPath,
      'srsPath': srsPath,
      'disableZk': disableZk,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? Uint8List(0);
  }
}
