package com.example.mopro_flutter

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import uniffi.mopro.generateNoirProof
import uniffi.mopro.verifyNoirProof
import uniffi.mopro.getNoirVerificationKey
import uniffi.mopro.getNumPublicInputsFromCircuit
import uniffi.mopro.parseProofWithPublicInputs

/** MoproFlutterPlugin */
class MoproFlutterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mopro_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "generateNoirProof") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val srsPath = call.argument<String>("srsPath")

            val inputs = call.argument<List<String>>("inputs") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing inputs",
                null
            )

            val onChain = call.argument<Boolean>("onChain") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing onChain",
                null
            )

            val vk = call.argument<ByteArray>("vk") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing vk",
                null
            )

            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = generateNoirProof(circuitPath, srsPath, inputs, onChain, vk, lowMemoryMode)
            result.success(res)
        } else if (call.method == "verifyNoirProof") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val proof = call.argument<ByteArray>("proof") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing proof",
                null
            )

            val onChain = call.argument<Boolean>("onChain") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing onChain",
                null
            )

            val vk = call.argument<ByteArray>("vk") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing vk",
                null
            )

            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = verifyNoirProof(circuitPath, proof, onChain, vk, lowMemoryMode)
            result.success(res)
        } else if (call.method == "getNoirVerificationKey") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val srsPath = call.argument<String>("srsPath")
            
            val onChain = call.argument<Boolean>("onChain") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing onChain",
                null
            )
            
            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = getNoirVerificationKey(circuitPath, srsPath, onChain, lowMemoryMode)
            result.success(res)
        } else if (call.method == "getNumPublicInputsFromCircuit") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val res = getNumPublicInputsFromCircuit(circuitPath)
            result.success(res.toInt())
        } else if (call.method == "parseProofWithPublicInputs") {
            val proof = call.argument<ByteArray>("proof") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing proof",
                null
            )

            val numPublicInputs = call.argument<Int>("numPublicInputs") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing numPublicInputs",
                null
            )

            val res = parseProofWithPublicInputs(proof, numPublicInputs.toUInt())
            val resultMap = mapOf(
                "proof" to res.proof,
                "publicInputs" to res.publicInputs,
                "numPublicInputs" to res.numPublicInputs.toInt()
            )
            result.success(resultMap)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
