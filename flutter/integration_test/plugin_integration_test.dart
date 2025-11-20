// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mopro_flutter_bindings/src/rust/third_party/mopro_wallet_connect_noir.dart';
import 'package:mopro_flutter_bindings/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await RustLib.init());

  testWidgets('Noir Proof Generation Test', (WidgetTester tester) async {
    var inputs = ["5", "3"];
    // Constants for Noir proof generation
    const bool onChain = true; // Use Keccak for Solidity compatibility
    const bool lowMemoryMode = false;
    final circuitPath =
        await copyAssetToFileSystem('assets/noir_multiplier2.json');
    final srsPath = await copyAssetToFileSystem('assets/noir_multiplier2.srs');
    final vkAsset = await rootBundle.load('assets/noir_multiplier2.vk');
    final vk = vkAsset.buffer.asUint8List();

    final Uint8List proofResult = await generateNoirProof(
        circuitPath: circuitPath,
        srsPath: srsPath,
        inputs: inputs,
        onChain: onChain,
        vk: vk,
        lowMemoryMode: lowMemoryMode);

    expect(proofResult, isNotNull);
    expect(proofResult.isNotEmpty, isTrue);
  });

  testWidgets('Noir Proof Verification Test', (WidgetTester tester) async {
    var inputs = ["5", "3"];
    // Constants for Noir proof generation
    const bool onChain = true; // Use Keccak for Solidity compatibility
    const bool lowMemoryMode = false;
    final circuitPath =
        await copyAssetToFileSystem('assets/noir_multiplier2.json');
    final srsPath = await copyAssetToFileSystem('assets/noir_multiplier2.srs');
    final vkAsset = await rootBundle.load('assets/noir_multiplier2.vk');
    final vk = vkAsset.buffer.asUint8List();

    final Uint8List proofResult = await generateNoirProof(
        circuitPath: circuitPath,
        srsPath: srsPath,
        inputs: inputs,
        onChain: onChain,
        vk: vk,
        lowMemoryMode: lowMemoryMode);

    final bool isValid = await verifyNoirProof(
      circuitPath: circuitPath,
      proof: proofResult,
      onChain: onChain,
      vk: vk,
      lowMemoryMode: lowMemoryMode,
    );

    expect(isValid, isTrue);
  });

  testWidgets('Noir Verification Key Generation Test',
      (WidgetTester tester) async {
    const bool onChain = true;
    const bool lowMemoryMode = false;
    final circuitPath =
        await copyAssetToFileSystem('assets/noir_multiplier2.json');
    final srsPath = await copyAssetToFileSystem('assets/noir_multiplier2.srs');

    final Uint8List vk = await getNoirVerificationKey(
      circuitPath: circuitPath,
      srsPath: srsPath,
      onChain: onChain,
      lowMemoryMode: lowMemoryMode,
    );

    expect(vk, isNotNull);
    expect(vk.isNotEmpty, isTrue);
  });
}

/// Copies an asset to a file and returns the file path
Future<String> copyAssetToFileSystem(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final directory = await getApplicationDocumentsDirectory();
  final filename = assetPath.split('/').last;
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file.path;
}
