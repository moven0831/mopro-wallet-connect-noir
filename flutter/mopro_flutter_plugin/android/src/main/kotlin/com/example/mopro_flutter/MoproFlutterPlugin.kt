package com.example.mopro_flutter

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import uniffi.mopro.generateNoirKeccakProofWithVk
import uniffi.mopro.verifyNoirKeccakProofWithVk
import uniffi.mopro.getNoirVerificationKeccakKey

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
        if (call.method == "generateNoirKeccakProofWithVk") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val srsPath = call.argument<String>("srsPath")

            val vk = call.argument<ByteArray>("vk") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing vk",
                null
            )

            val inputs = call.argument<List<String>>("inputs") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing inputs",
                null
            )

            val disableZk = call.argument<Boolean>("disableZk") ?: false
            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = generateNoirKeccakProofWithVk(circuitPath, srsPath, vk, inputs, disableZk, lowMemoryMode)
            result.success(res)
        } else if (call.method == "verifyNoirKeccakProofWithVk") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val vk = call.argument<ByteArray>("vk") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing vk",
                null
            )

            val proof = call.argument<ByteArray>("proof") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing proof",
                null
            )

            val disableZk = call.argument<Boolean>("disableZk") ?: false
            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = verifyNoirKeccakProofWithVk(circuitPath, vk, proof, disableZk, lowMemoryMode)
            result.success(res)
        } else if (call.method == "getNoirVerificationKeccakKey") {
            val circuitPath = call.argument<String>("circuitPath") ?: return result.error(
                "ARGUMENT_ERROR",
                "Missing circuitPath",
                null
            )

            val srsPath = call.argument<String>("srsPath")
            val disableZk = call.argument<Boolean>("disableZk") ?: false
            val lowMemoryMode = call.argument<Boolean>("lowMemoryMode") ?: false

            val res = getNoirVerificationKeccakKey(circuitPath, srsPath, disableZk, lowMemoryMode)
            result.success(res)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
