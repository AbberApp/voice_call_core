import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voice_call_core/voice_call_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Call Core Integration Tests', () {
    testWidgets('should initialize plugin successfully', (tester) async {
      final config = CoreSDKConfig(
        appName: 'Integration Test App',
        sensitiveConfig: IntegrationTestConfig(),
        enableRecording: true,
        enablePerformanceMonitoring: false,
      );

      await VoiceCallCore.initialize(config);
      expect(VoiceCallCore.isInitialized, true);
      
      // Clean up
      await VoiceCallCore.dispose();
    });

    testWidgets('should create managers successfully', (tester) async {
      final config = CoreSDKConfig(
        appName: 'Integration Test App',
        sensitiveConfig: IntegrationTestConfig(),
      );

      await VoiceCallCore.initialize(config);
      
      // Test recording manager creation
      final recordingManager = VoiceCallCore.instance.createRecordingManager();
      expect(recordingManager, isNotNull);
      expect(recordingManager.currentState, CallRecordingState.idle);
      
      // Test cloud storage manager creation
      final cloudManager = VoiceCallCore.instance.createCloudStorageManager();
      expect(cloudManager, isNotNull);
      
      // Clean up
      await VoiceCallCore.dispose();
    });
  });
}

/// Integration test configuration
class IntegrationTestConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://integration-test.example.com';
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/webhooks/calls';
  
  @override
  String get webrtcSocketUrl => 'wss://integration-test.example.com/webrtc';
  
  @override
  String get meetingSocketUrl => 'wss://integration-test.example.com/meeting';
  
  @override
  List<String> get stunServers => ['stun:stun.l.google.com:19302'];
  
  @override
  List<Map<String, dynamic>> get turnServers => [
    {
      'urls': ['turn:integration-test.example.com:3478'],
      'username': 'integration-test',
      'credential': 'integration-test',
    },
  ];
  
  @override
  String get firebaseProjectId => 'integration-test-project';
  
  @override
  String get firebaseStorageBucket => 'integration-test-project.appspot.com';
  
  @override
  String? get apiKey => 'integration-test-api-key';
  
  @override
  String? get secretKey => null;
}