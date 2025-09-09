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
        let circuitPath = args["circuitPath"] as? String,
        let vk = args["vk"] as? FlutterStandardTypedData,
        let inputs = args["inputs"] as? [String],
        let onChain = args["onChain"] as? Bool,
        let lowMemoryMode = args["lowMemoryMode"] as? Bool
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let srsPath = args["srsPath"] as? String

      do {
        let proofResult = try generateNoirProof(
          circuitPath: circuitPath, srsPath: srsPath, inputs: inputs, onChain: onChain, vk: vk.data, lowMemoryMode: lowMemoryMode)
        result(proofResult)
      } catch {
        result(
          FlutterError(
            code: "PROOF_GENERATION_ERROR", message: "Failed to generate proof",
            details: error.localizedDescription))
      }

    case "verifyNoirProof":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String,
        let proof = args["proof"] as? FlutterStandardTypedData,
        let onChain = args["onChain"] as? Bool,
        let vk = args["vk"] as? FlutterStandardTypedData,
        let lowMemoryMode = args["lowMemoryMode"] as? Bool
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      do {
        let valid = try verifyNoirProof(circuitPath: circuitPath, proof: proof.data, onChain: onChain, vk: vk.data, lowMemoryMode: lowMemoryMode)
        result(valid)
      } catch {
        result(
          FlutterError(
            code: "PROOF_VERIFICATION_ERROR", message: "Failed to verify proof",
            details: error.localizedDescription))
      }

    case "getNoirVerificationKey":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String,
        let onChain = args["onChain"] as? Bool,
        let lowMemoryMode = args["lowMemoryMode"] as? Bool
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      let srsPath = args["srsPath"] as? String

      do {
        let vkResult = try getNoirVerificationKey(
          circuitPath: circuitPath, srsPath: srsPath, onChain: onChain, lowMemoryMode: lowMemoryMode)
        result(vkResult)
      } catch {
        result(
          FlutterError(
            code: "VK_GENERATION_ERROR", message: "Failed to get verification key",
            details: error.localizedDescription))
      }

    case "getNumPublicInputsFromCircuit":
      guard let args = call.arguments as? [String: Any],
        let circuitPath = args["circuitPath"] as? String
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      do {
        let numInputs = try getNumPublicInputsFromCircuit(circuitPath: circuitPath)
        result(numInputs)
      } catch {
        result(
          FlutterError(
            code: "CIRCUIT_ANALYSIS_ERROR", message: "Failed to get number of public inputs",
            details: error.localizedDescription))
      }

    case "parseProofWithPublicInputs":
      guard let args = call.arguments as? [String: Any],
        let proof = args["proof"] as? FlutterStandardTypedData,
        let numPublicInputs = args["numPublicInputs"] as? Int32
      else {
        result(FlutterError(code: "ARGUMENT_ERROR", message: "Missing arguments", details: nil))
        return
      }

      do {
        let splitResult = try parseProofWithPublicInputs(proof: proof.data, numPublicInputs: UInt32(numPublicInputs))
        let resultDict: [String: Any] = [
          "proof": splitResult.proof,
          "publicInputs": splitResult.publicInputs,
          "numPublicInputs": splitResult.numPublicInputs
        ]
        result(resultDict)
      } catch {
        result(
          FlutterError(
            code: "PROOF_PARSING_ERROR", message: "Failed to parse proof with public inputs",
            details: error.localizedDescription))
      }


    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
