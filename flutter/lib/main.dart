import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

import 'wallet_connect_service.dart';

// Global navigator key for the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  bool isVerifyingOnChain = false;
  Exception? _error;
  bool _walletConnected = false;
  bool _isInitializing = true;

  // Controllers to handle user input
  final TextEditingController _controllerNoirA = TextEditingController();
  final TextEditingController _controllerNoirB = TextEditingController();
  
  // Smart contract details
  static const String contractAddress = "0x593ce6b2A205591b9bD520Dce4392ef67913EE4F";
  static const String contractABI = '''[
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
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]''';

  @override
  void initState() {
    super.initState();
    _controllerNoirA.text = "3";
    _controllerNoirB.text = "5";
    // Delay initialization to ensure the widget is properly built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWalletConnect();
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

  Widget _buildWalletSection() {
    if (_isInitializing) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Wallet Connection',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Initializing wallet connect...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wallet Connection',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_walletConnected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    const Text('Wallet Connected'),
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${WalletConnectService.connectedAddress ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Network: ${WalletConnectService.connectedChainName ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _disconnectWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.wallet, color: Colors.orange, size: 32),
                    SizedBox(height: 8),
                    Text('No Wallet Connected'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _connectWallet,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zero-Knowledge Proof Generator',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isProving) 
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextFormField(
              controller: _controllerNoirA,
              decoration: const InputDecoration(
                labelText: "Public input `a`",
                hintText: "For example, 3",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllerNoirB,
              decoration: const InputDecoration(
                labelText: "Public input `b`",
                hintText: "For example, 5",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_controllerNoirA.text.isEmpty || 
                                _controllerNoirB.text.isEmpty || 
                                isProving || isVerifyingOnChain) ? null : _generateProof,
                    icon: const Icon(Icons.create),
                    label: const Text("Generate Proof"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_noirProofResult == null || isProving || isVerifyingOnChain) ? null : _verifyProof,
                    icon: const Icon(Icons.verified),
                    label: const Text("Verify Local"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: (_noirProofResult == null || isProving || isVerifyingOnChain || !_walletConnected) ? null : _verifyOnChain,
              icon: isVerifyingOnChain 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_done),
              label: Text(isVerifyingOnChain ? "Verifying On-Chain..." : "Verify On-Chain"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _walletConnected ? null : Colors.grey,
              ),
            ),
            if (_noirProofResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Proof Generated Successfully',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proof byte length: ${_noirProofResult!.length} bytes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // Local verification result
                    if (_noirValid != null) ...[
                      Row(
                        children: [
                          Icon(
                            (_noirValid == true) ? Icons.check_circle : Icons.cancel,
                            color: (_noirValid == true) ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Local verification: ${_noirValid! ? "VALID" : "INVALID"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (_noirValid == true) ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // On-chain verification result
                    if (_onChainValid != null) ...[
                      Row(
                        children: [
                          Icon(
                            (_onChainValid == true) ? Icons.check_circle : Icons.cancel,
                            color: (_onChainValid == true) ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'On-chain verification: ${_onChainValid! ? "VALID" : "INVALID"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (_onChainValid == true) ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Proof Data', style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _noirProofResult.toString(),
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateProof() async {
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
      noirProofResult = await _moproFlutterPlugin.generateNoirProof(
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
      _noirValid = null; // Reset validity when new proof is generated
      _onChainValid = null; // Reset on-chain validity when new proof is generated
    });
  }

  Future<void> _verifyProof() async {
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
  }

  Future<void> _verifyOnChain() async {
    if (!_walletConnected) {
      setState(() {
        _error = Exception("Please connect your wallet first");
      });
      return;
    }

    if (_noirProofResult == null) {
      setState(() {
        _error = Exception("Please generate a proof first");
      });
      return;
    }

    setState(() {
      _error = null;
      isVerifyingOnChain = true;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    bool? valid;
    try {
      // Print proof byte length
      print("Proof byte length: ${_noirProofResult!.length}");
      
      // Print entire proof in hex format for debugging
      print("Full proof hex: ${hex.encode(_noirProofResult!)}");
      
      // Extract proof components from the full proof data
      // The proof contains: 4 bytes metadata + 32 bytes public input + 14080 bytes proof
      const int metadataSize = 4;
      const int publicInputSize = 32;
      const int expectedProofSize = 14080; // 440 * 32 bytes
      
      if (_noirProofResult!.length != metadataSize + publicInputSize + expectedProofSize) {
        throw Exception("Invalid proof size: expected ${metadataSize + publicInputSize + expectedProofSize}, got ${_noirProofResult!.length}");
      }
      
      // Extract metadata (first 4 bytes)
      final metadataBytes = _noirProofResult!.sublist(0, metadataSize);
      
      // Extract public input from the proof data
      final publicInputBytes = _noirProofResult!.sublist(metadataSize, metadataSize + publicInputSize);
      
      // Extract raw proof bytes (skip metadata and public input)
      final rawProofBytes = _noirProofResult!.sublist(metadataSize + publicInputSize);
      
      // Print each component in hex
      print("Metadata bytes (${metadataBytes.length}): ${hex.encode(metadataBytes)}");
      print("Public input bytes (${publicInputBytes.length}): ${hex.encode(publicInputBytes)}");
      print("Raw proof bytes (${rawProofBytes.length}): ${hex.encode(rawProofBytes)}");
      
      // Create Web3 client
      final rpcUrl = 'https://ethereum-sepolia.publicnode.com';
      final httpClient = Web3Client(rpcUrl, http.Client());
      
      // Create contract instance
      final contract = DeployedContract(
        ContractAbi.fromJson(contractABI, 'HonkVerifier'),
        EthereumAddress.fromHex(contractAddress),
      );
      
      // Prepare proof and public inputs for the contract (web3dart expects Uint8List)
      final publicInputsArray = [publicInputBytes];
      
      print("Sending proof bytes (${rawProofBytes.length}): 0x${hex.encode(rawProofBytes).substring(0, 50)}...");
      print("Sending public input bytes (${publicInputBytes.length}): 0x${hex.encode(publicInputBytes)}");
      
      // Call the verify function
      final verifyFunction = contract.function('verify');
      final result = await httpClient.call(
        contract: contract,
        function: verifyFunction,
        params: [rawProofBytes, publicInputsArray],
      );
      
      valid = result.first as bool;
      
      httpClient.dispose();
    } on Exception catch (e) {
      print("On-chain verification error: $e");
      valid = false;
      setState(() {
        _error = e;
      });
    } catch (e) {
      print("On-chain verification error: $e");
      valid = false;
      setState(() {
        _error = Exception(e.toString());
      });
    }

    if (!mounted) return;

    setState(() {
      _onChainValid = valid;
      isVerifyingOnChain = false;
    });
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
