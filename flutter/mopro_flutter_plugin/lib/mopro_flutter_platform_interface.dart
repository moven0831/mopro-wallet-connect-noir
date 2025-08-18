import 'dart:typed_data';

import 'package:mopro_flutter/mopro_types.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mopro_flutter_method_channel.dart';

abstract class MoproFlutterPlatform extends PlatformInterface {
  /// Constructs a MoproFlutterPlatform.
  MoproFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MoproFlutterPlatform _instance = MethodChannelMoproFlutter();

  /// The default instance of [MoproFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMoproFlutter].
  static MoproFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MoproFlutterPlatform] when
  /// they register themselves.
  static set instance(MoproFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Uint8List> generateNoirKeccakProofWithVk(
      String circuitPath, String? srsPath, Uint8List vk, List<String> inputs,
      {bool disableZk = false, bool lowMemoryMode = false}) {
    throw UnimplementedError('generateNoirKeccakProofWithVk() has not been implemented.');
  }

  Future<bool> verifyNoirKeccakProofWithVk(String circuitPath, Uint8List vk, Uint8List proof,
      {bool disableZk = false, bool lowMemoryMode = false}) {
    throw UnimplementedError('verifyNoirKeccakProofWithVk() has not been implemented.');
  }

  Future<Uint8List> getNoirVerificationKeccakKey(String circuitPath, String? srsPath,
      {bool disableZk = false, bool lowMemoryMode = false}) {
    throw UnimplementedError('getNoirVerificationKeccakKey() has not been implemented.');
  }
}
