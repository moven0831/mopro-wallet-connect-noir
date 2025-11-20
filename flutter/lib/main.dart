import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mopro_flutter_bindings/src/rust/third_party/mopro_wallet_connect_noir.dart';
import 'package:mopro_flutter_bindings/src/rust/frb_generated.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

import 'wallet_connect_service.dart';

// Global navigator key for the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mopro Wallet Connect Noir',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _noirProofResult;
  bool? _noirValid;
  bool? _onChainValid;
  bool isProving = false;
  bool isVerifyingOnChain = false;
  Exception? _error;
  bool _walletConnected = false;
  bool _isInitializing = true;
  List<String>? _proofInputs;
  Uint8List? _verificationKey;

  // Timing measurements
  Duration? _proofGenerationTime;
  Duration? _localVerificationTime;
  Duration? _onChainVerificationTime;

  // Controllers to handle user input
  final TextEditingController _controllerNoirA = TextEditingController();
  final TextEditingController _controllerNoirB = TextEditingController();

  // Smart contract details
  static const String contractAddress = "0x3C9f0361F4120D236F752035D22D1e850EA0f5E6";
  static const String contractABI = '''[
    {
      "inputs": [],
      "name": "ConsistencyCheckFailed",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "GeminiChallengeInSubgroup",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "ProofLengthWrong",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "PublicInputsLengthWrong",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "ShpleminiFailed",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "SumcheckFailed",
      "type": "error"
    },
    {
      "inputs": [
        {
          "internalType": "bytes",
          "name": "proof",
          "type": "bytes"
        },
        {
          "internalType": "bytes32[]",
          "name": "publicInputs",
          "type": "bytes32[]"
        }
      ],
      "name": "verify",
      "outputs": [
        {
          "internalType": "bool",
          "name": "verified",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]''';

  // Helper function to copy assets to file system for native code access
  Future<String> copyAssetToFileSystem(String assetPath) async {
    // Load the asset as bytes
    final byteData = await rootBundle.load(assetPath);
    // Get the app's document directory
    final directory = await getApplicationDocumentsDirectory();
    // Strip off the initial dirs from the filename
    final fileName = assetPath.split('/').last;
    final file = File('${directory.path}/$fileName');
    // Write the bytes to a file in the file system
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path; // Return the file path
  }

  @override
  void initState() {
    super.initState();
    _controllerNoirA.text = "3";
    _controllerNoirB.text = "5";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWalletConnect();
      _loadVerificationKey();
    });
  }

  Future<void> _initializeWalletConnect() async {
    try {
      await WalletConnectService.initialize(context);
      // Add listener for wallet connection changes
      WalletConnectService.addListener(_onWalletConnectionChanged);
      if (mounted) {
        setState(() {
          _walletConnected = WalletConnectService.isConnected;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Failed to initialize wallet connect: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        final errorMessage = e.toString();
        final isConfigError = errorMessage.contains('Project ID not configured');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConfigError
                  ? 'Configuration Error: Missing PROJECT_ID'
                  : 'Failed to initialize wallet connect: $errorMessage'
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: isConfigError ? 8 : 5),
            action: isConfigError ? SnackBarAction(
              label: 'Help',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Configuration Required'),
                    content: const Text(
                      'To use wallet connectivity, you need to:\n\n'
                      '1. Get a Project ID from cloud.reown.com\n'
                      '2. Run the app with:\n'
                      '   flutter run --dart-define=PROJECT_ID=your_project_id\n\n'
                      'See WALLET_CONNECT_SETUP.md for detailed instructions.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ) : null,
          ),
        );
      }
    }
  }

  void _onWalletConnectionChanged() {
    if (mounted) {
      setState(() {
        _walletConnected = WalletConnectService.isConnected;
      });
    }
  }

  Future<void> _loadVerificationKey() async {
    try {
      // Load existing verification key from assets
      final byteData = await rootBundle.load('assets/noir_multiplier2.vk');
      setState(() {
        _verificationKey = byteData.buffer.asUint8List();
      });
      print('Verification key loaded successfully (${_verificationKey!.length} bytes)');
    } catch (e) {
      print('Failed to load verification key: $e');
      if (mounted) {
        setState(() {
          _error = Exception('Failed to load verification key: $e');
        });
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final milliseconds = duration.inMilliseconds;
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else {
      return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  @override
  void dispose() {
    WalletConnectService.removeListener(_onWalletConnectionChanged);
    WalletConnectService.dispose();
    _controllerNoirA.dispose();
    _controllerNoirB.dispose();
    super.dispose();
  }

  Future<void> _connectWallet() async {
    try {
      await WalletConnectService.connect();
    } catch (e) {
      print('Error connecting wallet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect wallet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      await WalletConnectService.disconnect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect wallet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateNoirProof() async {
    if (_controllerNoirA.text.isEmpty ||
        _controllerNoirB.text.isEmpty ||
        isProving) {
      return;
    }

    setState(() {
      _error = null;
      isProving = true;
      _noirProofResult = null;
      _noirValid = null;
      _onChainValid = null;
      _proofGenerationTime = null;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    Uint8List? noirProofResult;
    final stopwatch = Stopwatch()..start();
    try {
      var inputs = [_controllerNoirA.text, _controllerNoirB.text];
      _proofInputs = inputs;

      // Constants for Noir proof generation
      const bool onChain = true;
      const bool lowMemoryMode = false;

      if (_verificationKey == null) {
        throw Exception('Verification key not loaded. Please restart the app.');
      }

      // Copy assets to file system for native code access
      final circuitPath = await copyAssetToFileSystem('assets/noir_multiplier2.json');
      final srsPath = await copyAssetToFileSystem('assets/noir_multiplier2.srs');

      noirProofResult = await generateNoirProof(
        circuitPath: circuitPath,
        srsPath: srsPath,
        inputs: inputs,
        onChain: onChain,
        vk: _verificationKey!,
        lowMemoryMode: lowMemoryMode,
      );
      stopwatch.stop();
      _proofGenerationTime = stopwatch.elapsed;
      // Store the inputs for later use in verification
      _proofInputs = inputs;
    } on Exception catch (e) {
      print("Error: $e");
      stopwatch.stop();
      noirProofResult = null;
      _proofInputs = null;
      setState(() {
        _error = e;
        _proofGenerationTime = null;
      });
    }

    if (!mounted) return;

    setState(() {
      isProving = false;
      _noirProofResult = noirProofResult;
    });
  }

  Future<void> _verifyNoirProof() async {
    if (_controllerNoirA.text.isEmpty ||
        _controllerNoirB.text.isEmpty ||
        isProving) {
      return;
    }

    setState(() {
      _error = null;
      isProving = true;
      _localVerificationTime = null;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    bool? valid;
    final stopwatch = Stopwatch()..start();
    try {
      var proofResult = _noirProofResult;
      var vk = _verificationKey;

      if (vk == null) {
        throw Exception("Verification key not available. Generate proof first.");
      }

      if (proofResult == null) {
        throw Exception("No proof available. Generate proof first.");
      }

      // Constants for Noir proof verification
      const bool onChain = true; // Use Keccak for Solidity compatibility
      const bool lowMemoryMode = false;

      // Copy circuit asset to file system for native code access
      final circuitPath = await copyAssetToFileSystem('assets/noir_multiplier2.json');

      valid = await verifyNoirProof(
        circuitPath: circuitPath,
        proof: proofResult,
        onChain: onChain,
        vk: vk,
        lowMemoryMode: lowMemoryMode,
      );
      stopwatch.stop();
      _localVerificationTime = stopwatch.elapsed;
    } on Exception catch (e) {
      print("Error: $e");
      stopwatch.stop();
      valid = false;
      setState(() {
        _error = e;
        _localVerificationTime = null;
      });
    } on TypeError catch (e) {
      print("Error: $e");
      stopwatch.stop();
      valid = false;
      setState(() {
        _error = Exception(e.toString());
        _localVerificationTime = null;
      });
    }

    if (!mounted) return;

    setState(() {
      _noirValid = valid;
      isProving = false;
    });
  }

  Future<void> _verifyOnChain() async {
    if (_noirProofResult == null) {
      setState(() {
        _error = Exception("Please generate a proof first");
      });
      return;
    }

    setState(() {
      _error = null;
      isVerifyingOnChain = true;
      _onChainVerificationTime = null;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    bool? valid;
    final stopwatch = Stopwatch()..start();
    try {
      final originalProof = _noirProofResult!;

      // Copy circuit asset to file system for native code access
      final circuitPath = await copyAssetToFileSystem('assets/noir_multiplier2.json');

      // Get the number of public inputs for this circuit
      final numPublicInputs = await getNumPublicInputsFromCircuit(circuitPath: circuitPath);
      print('Number of public inputs: $numPublicInputs');

      // Parse the proof into proof bytes and public inputs using Rust functions
      final parsedResult = await parseProofWithPublicInputs(proof: originalProof, numPublicInputs: numPublicInputs);
      final proof = parsedResult.proof;
      final publicInputs = parsedResult.publicInputs;

      print('Proof: ${hex.encode(proof)}');
      print('Public inputs: ${publicInputs.map((input) => hex.encode(input)).join(', ')}');

      // Create Web3 client
      final rpcUrl = 'https://ethereum-sepolia.publicnode.com';
      final httpClient = Web3Client(rpcUrl, http.Client());

      // Create contract instance
      final contract = DeployedContract(
        ContractAbi.fromJson(contractABI, 'HonkVerifier'),
        EthereumAddress.fromHex(contractAddress),
      );

      // Call the verify function
      final verifyFunction = contract.function('verify');
      final verifyResult = await httpClient.call(
        contract: contract,
        function: verifyFunction,
        params: [proof, publicInputs],
      );

      valid = verifyResult.first as bool;
      stopwatch.stop();
      _onChainVerificationTime = stopwatch.elapsed;

      httpClient.dispose();
    } on Exception catch (e) {
      print("On-chain verification error: $e");
      stopwatch.stop();
      valid = false;
      setState(() {
        _error = e;
        _onChainVerificationTime = null;
      });
    } catch (e) {
      print("On-chain verification error: $e");
      stopwatch.stop();
      valid = false;
      setState(() {
        _error = Exception(e.toString());
        _onChainVerificationTime = null;
      });
    }

    if (!mounted) return;

    setState(() {
      _onChainValid = valid;
      isVerifyingOnChain = false;
    });
  }

  Widget _buildWalletSection() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (_walletConnected) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Connected to wallet'),
                ],
              ),
              const SizedBox(height: 8),
              if (WalletConnectService.connectedAddress != null) ...[
                Text(
                  'Address: ${WalletConnectService.connectedAddress}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (WalletConnectService.connectedChainName != null) ...[
                Text(
                  'Chain: ${WalletConnectService.connectedChainName}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _disconnectWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Disconnect'),
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Not connected'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _connectWallet,
                child: const Text('Connect Wallet'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Noir Zero-Knowledge Proof',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isProving || isVerifyingOnChain)
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error.toString(),
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _controllerNoirA,
                decoration: const InputDecoration(
                  labelText: "Public input `a`",
                  hintText: "For example, 3",
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_controllerNoirA.text.isEmpty ||
                          _controllerNoirB.text.isEmpty ||
                          isProving)
                          ? null
                          : _generateNoirProof,
                      child: const Text("Generate Proof"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_noirProofResult == null || isProving)
                          ? null
                          : _verifyNoirProof,
                      child: const Text("Verify Proof"),
                    ),
                  ),
                ],
              ),
            ),
            if (_walletConnected && _noirProofResult != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifyingOnChain ? null : _verifyOnChain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Verify On-Chain"),
                  ),
                ),
              ),
            if (_noirProofResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Proof Generated',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_proofInputs != null)
                      Text('Inputs: a=${_proofInputs![0]}, b=${_proofInputs![1]}'),
                    Text('Proof size: ${_noirProofResult!.length} bytes'),
                    if (_proofGenerationTime != null)
                      Text('Time: ${_formatDuration(_proofGenerationTime)}'),
                    if (_noirValid != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _noirValid! ? Icons.verified : Icons.cancel,
                            color: _noirValid! ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Local verification: ${_noirValid! ? "VALID" : "INVALID"}',
                            style: TextStyle(
                              color: _noirValid! ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_localVerificationTime != null)
                        Text('Time: ${_formatDuration(_localVerificationTime)}'),
                    ],
                    if (_onChainValid != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _onChainValid! ? Icons.verified : Icons.cancel,
                            color: _onChainValid! ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'On-chain verification: ${_onChainValid! ? "VALID" : "INVALID"}',
                            style: TextStyle(
                              color: _onChainValid! ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_onChainVerificationTime != null)
                        Text('Time: ${_formatDuration(_onChainVerificationTime)}'),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mopro Wallet Connect Noir'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_walletConnected)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.circle, color: Colors.green, size: 12),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWalletSection(),
            _buildProofSection(),
          ],
        ),
      ),
    );
  }
}
