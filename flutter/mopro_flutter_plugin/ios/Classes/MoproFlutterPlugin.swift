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
    case "generateNoirProof":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let srsPath = args["srsPath"] as? String

      guard let args = call.arguments as? [String: Any],
        let inputs = args["inputs"] as? [String]
      else {
        result(
          FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments inputs", details: nil))
        return
      }

      do {
        let proofResult = try generateNoirProof(
          circuitPath: circuitPath, srsPath: srsPath, inputs: inputs)
        result(proofResult)
      } catch {
        result(
          FlutterError(
            code: "PROOF_GENERATION_ERROR", message: "Failed to generate proof",
            details: error.localizedDescription))
      }

    case "verifyNoirProof":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      guard let args = call.arguments as? [String: Any],
        let proof = args["proof"] as? FlutterStandardTypedData
      else {
        result(
          FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments proof", details: nil))
        return
      }

      do {
        let valid = try verifyNoirProof(circuitPath: circuitPath, proof: proof.data)
        result(valid)
      } catch {
        result(
          FlutterError(
            code: "PROOF_VERIFICATION_ERROR", message: "Failed to verify proof",
            details: error.localizedDescription))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
