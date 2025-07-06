import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'config.dart';
import 'main.dart';

class WalletConnectService {
  static ReownAppKitModal? _appKitModal;
  static bool _isInitialized = false;
  
  // Ethereum mainnet configuration
  static const ethereumChain = ReownAppKitModalNetworkInfo(
    name: 'Ethereum',
    chainId: '1',
    currency: 'ETH',
    rpcUrl: 'https://ethereum.publicnode.com',
    explorerUrl: 'https://etherscan.io',
    isTestNetwork: false,
  );
  
  // Sepolia testnet configuration
  static const sepoliaChain = ReownAppKitModalNetworkInfo(
    name: 'Sepolia',
    chainId: '11155111',
    currency: 'ETH',
    rpcUrl: 'https://ethereum-sepolia.publicnode.com',
    explorerUrl: 'https://sepolia.etherscan.io',
    isTestNetwork: true,
  );
  
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    // Validate configuration first
    AppConfig.validateConfiguration();
    
    try {
      // Use the global navigator key's context to ensure proper MaterialApp context
      final appContext = navigatorKey.currentContext ?? context;
      
      _appKitModal = ReownAppKitModal(
        context: appContext,
        projectId: AppConfig.projectId,
        metadata: const PairingMetadata(
          name: AppConfig.appName,
          description: AppConfig.appDescription,
          url: AppConfig.appUrl,
          icons: [AppConfig.appIcon],
        ),
        // Removed SIWE configuration as it's not available in current Flutter API
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:11155111'], // Sepolia testnet
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
        // Removed optionalNamespaces as OptionalNamespace is not available
        includedWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Coinbase Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase
          '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369', // Rainbow
        },
        featuredWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662', // Coinbase Wallet
        },
      );
      
      await _appKitModal!.init();
      _isInitialized = true;
      
      print('Reown AppKit initialized successfully');
    } catch (e) {
      print('Error initializing Reown AppKit: $e');
      rethrow;
    }
  }
  
  static ReownAppKitModal? get appKitModal => _appKitModal;
  
  static bool get isConnected => _appKitModal?.isConnected ?? false;
  
  // Updated session management with proper null checking
  static String? get connectedAddress {
    final session = _appKitModal?.session;
    if (session == null) return null;
    
    try {
      final accounts = session.getAccounts();
      if (accounts != null && accounts.isNotEmpty) {
        return accounts.first.split(':').last;
      }
    } catch (e) {
      print('Error getting connected address: $e');
    }
    return null;
  }
  
  static String? get connectedChainId => _appKitModal?.selectedChain?.chainId;
  
  static String? get connectedChainName => _appKitModal?.selectedChain?.name;
  
  static Future<void> connect() async {
    if (!_isInitialized) {
      throw Exception('WalletConnectService not initialized. Call initialize() first.');
    }
    
    try {
      await _appKitModal!.openModalView();
    } catch (e) {
      print('Error connecting wallet: $e');
      rethrow;
    }
  }
  
  static Future<void> disconnect() async {
    if (!_isInitialized) return;
    
    try {
      await _appKitModal!.disconnect();
    } catch (e) {
      print('Error disconnecting wallet: $e');
      rethrow;
    }
  }
  
  static void addListener(VoidCallback listener) {
    _appKitModal?.addListener(listener);
  }
  
  static void removeListener(VoidCallback listener) {
    _appKitModal?.removeListener(listener);
  }
  
  static void dispose() {
    _appKitModal?.dispose();
    _isInitialized = false;
  }
}

