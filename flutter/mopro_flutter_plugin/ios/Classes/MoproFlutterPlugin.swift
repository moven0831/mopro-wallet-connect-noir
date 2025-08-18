import Flutter
import UIKit

public class MoproFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mopro_flutter", binaryMessenger: registrar.messenger())
    let instance = MoproFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "generateNoirKeccakProofWithVk":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String,
        let vk = args["vk"] as? FlutterStandardTypedData,
        let inputs = args["inputs"] as? [String]
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let srsPath = args["srsPath"] as? String
      let disableZk = args["disableZk"] as? Bool ?? false
      let lowMemoryMode = args["lowMemoryMode"] as? Bool ?? false

      do {
        let proofResult = try generateNoirKeccakProofWithVk(
          circuitPath: circuitPath, srsPath: srsPath, vk: vk.data, inputs: inputs, disableZk: disableZk, lowMemoryMode: lowMemoryMode)
        result(proofResult)
      } catch {
        result(
          FlutterError(
            code: "PROOF_GENERATION_ERROR", message: "Failed to generate proof with VK",
            details: error.localizedDescription))
      }

    case "verifyNoirKeccakProofWithVk":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String,
        let vk = args["vk"] as? FlutterStandardTypedData,
        let proof = args["proof"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let disableZk = args["disableZk"] as? Bool ?? false
      let lowMemoryMode = args["lowMemoryMode"] as? Bool ?? false

      do {
        let valid = try verifyNoirKeccakProofWithVk(circuitPath: circuitPath, vk: vk.data, proof: proof.data, disableZk: disableZk, lowMemoryMode: lowMemoryMode)
        result(valid)
      } catch {
        result(
          FlutterError(
            code: "PROOF_VERIFICATION_ERROR", message: "Failed to verify proof with VK",
            details: error.localizedDescription))
      }

    case "getNoirVerificationKeccakKey":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let srsPath = args["srsPath"] as? String
      let disableZk = args["disableZk"] as? Bool ?? false
      let lowMemoryMode = args["lowMemoryMode"] as? Bool ?? false

      do {
        let vkResult = try getNoirVerificationKeccakKey(
          circuitPath: circuitPath, srsPath: srsPath, disableZk: disableZk, lowMemoryMode: lowMemoryMode)
        result(vkResult)
      } catch {
        result(
          FlutterError(
            code: "VK_GENERATION_ERROR", message: "Failed to get verification key",
            details: error.localizedDescription))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
