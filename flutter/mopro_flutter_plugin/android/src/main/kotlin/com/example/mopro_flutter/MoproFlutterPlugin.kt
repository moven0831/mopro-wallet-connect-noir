package com.example.mopro_flutter

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import uniffi.mopro.generateNoirProof
import uniffi.mopro.verifyNoirProof

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

            val res = generateNoirProof(circuitPath, srsPath, inputs)
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

            val res = verifyNoirProof(circuitPath, proof)
            result.success(res)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
