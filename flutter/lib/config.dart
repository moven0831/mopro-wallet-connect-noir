class AppConfig {
  // Get Project ID from environment variable using --dart-define=PROJECT_ID=your_project_id
  static const String projectId = String.fromEnvironment(
    'PROJECT_ID',
    defaultValue: '',
  );
  
  // App metadata
  static const String appName = 'Mopro Wallet Connect Noir';
  static const String appDescription = 'A Flutter app for generating and verifying Noir proofs with wallet connectivity';
  static const String appUrl = 'https://github.com/your-username/mopro-wallet-connect-noir';
  static const String appIcon = 'https://avatars.githubusercontent.com/u/37784886';
  
  // Validation
  static bool get isProjectIdValid => projectId.isNotEmpty;
  
  // Environment check
  static void validateConfiguration() {
    if (!isProjectIdValid) {
      throw Exception(
        'Project ID not configured! Please:\n'
        '1. Go to https://cloud.reown.com\n'
        '2. Create a new project\n'
        '3. Copy your Project ID\n'
        '4. Run your app with: flutter run --dart-define=PROJECT_ID=your_project_id_here'
      );
    }
  }
} 