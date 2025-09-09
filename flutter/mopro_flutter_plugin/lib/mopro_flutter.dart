import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mopro_flutter/mopro_types.dart';
import 'package:path_provider/path_provider.dart';

import 'mopro_flutter_platform_interface.dart';

class MoproFlutter {
  Future<String> copyAssetToFileSystem(String assetPath) async {
    // Load the asset as bytes
    final byteData = await rootBundle.load(assetPath);
    // Get the app's document directory (or other accessible directory)
    final directory = await getApplicationDocumentsDirectory();
    //Strip off the initial dirs from the filename
    assetPath = assetPath.split('/').last;

    final file = File('${directory.path}/$assetPath');

    // Write the bytes to a file in the file system
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path; // Return the file path
  }

  // New API methods matching latest demo patterns
  Future<Uint8List> generateNoirProof(
      String circuitFile, String? srsFile, List<String> inputs, bool onChain, Uint8List vk, bool lowMemoryMode) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    String? srsPath;
    if (srsFile != null) {
      srsPath = await copyAssetToFileSystem(srsFile);
    }
    return await MoproFlutterPlatform.instance
        .generateNoirProof(circuitPath, srsPath, inputs, onChain, vk, lowMemoryMode);
  }

  Future<bool> verifyNoirProof(String circuitFile, Uint8List proof, bool onChain, Uint8List vk, bool lowMemoryMode) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    return await MoproFlutterPlatform.instance.verifyNoirProof(circuitPath, proof, onChain, vk, lowMemoryMode);
  }

  Future<Uint8List> getNoirVerificationKey(String circuitFile, String? srsFile, bool onChain, bool lowMemoryMode) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    String? srsPath;
    if (srsFile != null) {
      srsPath = await copyAssetToFileSystem(srsFile);
    }
    return await MoproFlutterPlatform.instance.getNoirVerificationKey(circuitPath, srsPath, onChain, lowMemoryMode);
  }


  Future<int> getNumPublicInputsFromCircuit(String circuitFile) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    return await MoproFlutterPlatform.instance.getNumPublicInputsFromCircuit(circuitPath);
  }

  Future<ProofWithPublicInputs> parseProofWithPublicInputs(Uint8List proof, int numPublicInputs) async {
    return await MoproFlutterPlatform.instance.parseProofWithPublicInputs(proof, numPublicInputs);
  }

}
