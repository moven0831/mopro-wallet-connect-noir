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

  Future<Uint8List> generateNoirProof(
      String circuitPath, String? srsPath, List<String> inputs) {
    throw UnimplementedError('generateNoirProof() has not been implemented.');
  }

  Future<bool> verifyNoirProof(String circuitPath, Uint8List proof) {
    throw UnimplementedError('verifyNoirProof() has not been implemented.');
  }
}
