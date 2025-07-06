import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? _noirProofResult;
  bool? _noirValid;
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  Exception? _error;

  // Controllers to handle user input
  final TextEditingController _controllerNoirA = TextEditingController();
  final TextEditingController _controllerNoirB = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerNoirA.text = "3";
    _controllerNoirB.text = "5";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Noir Proof Generator'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isProving) const CircularProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_error.toString()),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _controllerNoirA,
                    decoration: const InputDecoration(
                      labelText: "Public input `a`",
                      hintText: "For example, 3",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _controllerNoirB,
                    decoration: const InputDecoration(
                      labelText: "Public input `b`",
                      hintText: "For example, 5",
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                          onPressed: () async {
                            if (_controllerNoirA.text.isEmpty || _controllerNoirB.text.isEmpty || isProving) {
                              return;
                            }
                            setState(() {
                              _error = null;
                              isProving = true;
                            });

                            FocusManager.instance.primaryFocus?.unfocus();
                            Uint8List? noirProofResult;
                            try {
                              var inputs = [
                                _controllerNoirA.text,
                                _controllerNoirB.text
                              ];
                              noirProofResult =
                                  await _moproFlutterPlugin.generateNoirProof(
                                      "assets/noir_multiplier2.json",
                                      null,
                                      inputs);
                            } on Exception catch (e) {
                              print("Error: $e");
                              noirProofResult = null;
                              setState(() {
                                _error = e;
                              });
                            }

                            if (!mounted) return;

                            setState(() {
                              isProving = false;
                              _noirProofResult = noirProofResult;
                            });
                          },
                          child: const Text("Generate Proof")),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                          onPressed: () async {
                            if (_controllerNoirA.text.isEmpty || _controllerNoirB.text.isEmpty || isProving) {
                              return;
                            }
                            setState(() {
                              _error = null;
                              isProving = true;
                            });

                            FocusManager.instance.primaryFocus?.unfocus();
                            bool? valid;
                            try {
                              var proofResult = _noirProofResult;
                              valid = await _moproFlutterPlugin.verifyNoirProof(
                                  "assets/noir_multiplier2.json",
                                  proofResult!);
                            } on Exception catch (e) {
                              print("Error: $e");
                              valid = false;
                              setState(() {
                                _error = e;
                              });
                            } on TypeError catch (e) {
                              print("Error: $e");
                              valid = false;
                              setState(() {
                                _error = Exception(e.toString());
                              });
                            }

                            if (!mounted) return;

                            setState(() {
                              _noirValid = valid;
                              isProving = false;
                            });
                          },
                          child: const Text("Verify Proof")),
                    ),
                  ],
                ),
                if (_noirProofResult != null)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Proof is valid: ${_noirValid ?? false}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text('Proof: ${_noirProofResult ?? ""}'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
