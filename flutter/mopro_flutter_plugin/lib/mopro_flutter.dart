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

  Future<Uint8List> generateNoirKeccakProofWithVk(
      String circuitFile, String? srsFile, Uint8List vk, List<String> inputs,
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    String? srsPath;
    if (srsFile != null) {
      srsPath = await copyAssetToFileSystem(srsFile);
    }
    return await MoproFlutterPlatform.instance
        .generateNoirKeccakProofWithVk(circuitPath, srsPath, vk, inputs, 
            disableZk: disableZk, lowMemoryMode: lowMemoryMode);
  }

  Future<bool> verifyNoirKeccakProofWithVk(String circuitFile, Uint8List vk, Uint8List proof,
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    return await MoproFlutterPlatform.instance.verifyNoirKeccakProofWithVk(circuitPath, vk, proof,
        disableZk: disableZk, lowMemoryMode: lowMemoryMode);
  }

  Future<Uint8List> getNoirVerificationKeccakKey(String circuitFile, String? srsFile,
      {bool disableZk = false, bool lowMemoryMode = false}) async {
    String circuitPath = await copyAssetToFileSystem(circuitFile);
    String? srsPath;
    if (srsFile != null) {
      srsPath = await copyAssetToFileSystem(srsFile);
    }
    return await MoproFlutterPlatform.instance.getNoirVerificationKeccakKey(circuitPath, srsPath,
        disableZk: disableZk, lowMemoryMode: lowMemoryMode);
  }
}
