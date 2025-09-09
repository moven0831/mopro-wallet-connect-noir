import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mopro_flutter/mopro_types.dart';

import 'mopro_flutter_platform_interface.dart';

/// An implementation of [MoproFlutterPlatform] that uses method channels.
class MethodChannelMoproFlutter extends MoproFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mopro_flutter');

  // New API methods matching latest demo patterns
  @override
  Future<Uint8List> generateNoirProof(
      String circuitPath, String? srsPath, List<String> inputs, bool onChain, Uint8List vk, bool lowMemoryMode) async {
    final result = await methodChannel.invokeMethod<Uint8List>('generateNoirProof', {
      'circuitPath': circuitPath,
      'srsPath': srsPath,
      'inputs': inputs,
      'onChain': onChain,
      'vk': vk,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? Uint8List(0);
  }

  @override
  Future<bool> verifyNoirProof(String circuitPath, Uint8List proof, bool onChain, Uint8List vk, bool lowMemoryMode) async {
    final result = await methodChannel.invokeMethod<bool>('verifyNoirProof', {
      'circuitPath': circuitPath,
      'proof': proof,
      'onChain': onChain,
      'vk': vk,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? false;
  }

  @override
  Future<Uint8List> getNoirVerificationKey(String circuitPath, String? srsPath, bool onChain, bool lowMemoryMode) async {
    final result = await methodChannel.invokeMethod<Uint8List>('getNoirVerificationKey', {
      'circuitPath': circuitPath,
      'srsPath': srsPath,
      'onChain': onChain,
      'lowMemoryMode': lowMemoryMode,
    });
    return result ?? Uint8List(0);
  }


  @override
  Future<int> getNumPublicInputsFromCircuit(String circuitPath) async {
    final result = await methodChannel.invokeMethod<int>('getNumPublicInputsFromCircuit', {
      'circuitPath': circuitPath,
    });
    return result ?? 0;
  }

  @override
  Future<ProofWithPublicInputs> parseProofWithPublicInputs(Uint8List proof, int numPublicInputs) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('parseProofWithPublicInputs', {
      'proof': proof,
      'numPublicInputs': numPublicInputs,
    });
    return ProofWithPublicInputs.fromMap(Map<String, dynamic>.from(result ?? {}));
  }

}
