# Voice Call Core

[![pub package](https://img.shields.io/pub/v/voice_call_core.svg)](https://pub.dev/packages/voice_call_core)

A secure, reusable Flutter package for voice call functionality without UI components.

## 🚀 Features

- 🎙️ **Call Recording**: High-quality audio recording with cloud storage
- ☁️ **Cloud Storage**: Automatic upload to Firebase Storage
- 🔒 **Security First**: No hardcoded sensitive data
- 📊 **Performance Monitoring**: Built-in call quality metrics
- 🎨 **UI Agnostic**: Bring your own interface
- 🔧 **Configurable**: Flexible configuration system

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  voice_call_core: ^1.0.0
```

## 🔧 Quick Start

### 1. Create Configuration

First, implement the `SensitiveConfig` interface with your app's configuration:

```dart
import 'package:voice_call_core/voice_call_core.dart';

class MyAppConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://api.myapp.com';
  
  @override
  String get webrtcSocketUrl => 'wss://ws.myapp.com/webrtc';
  
  @override
  String get meetingSocketUrl => 'wss://ws.myapp.com/meeting';
  
  @override
  List<String> get stunServers => [
    'stun:stun.myapp.com:3478',
    'stun:stun.l.google.com:19302', // Fallback
  ];
  
  @override
  List<Map<String, dynamic>> get turnServers => [
    {
      'urls': ['turn:turn.myapp.com:3478'],
      'username': 'your-turn-username',
      'credential': 'your-turn-password',
    }
  ];
  
  @override
  String get firebaseProjectId => 'your-firebase-project';
  
  @override
  String get firebaseStorageBucket => 'your-firebase-project.appspot.com';
  
  @override
  String? get apiKey => 'your-api-key';
  
  @override
  String? get secretKey => null;
}
```

### 2. Initialize SDK

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await VoiceCallCore.initialize(
    CoreSDKConfig(
      appName: 'My App',
      sensitiveConfig: MyAppConfig(),
      qualityConfig: const WebRTCQualityConfig.highQuality(),
      enableRecording: true,
      enablePerformanceMonitoring: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Use Recording Manager

```dart
class CallService {
  late final CallRecordingManager _recordingManager;
  
  void initialize() {
    _recordingManager = VoiceCallCore.instance.createRecordingManager(
      config: CallRecordingConfig.highQualityConfig(),
    );
    
    // Listen to recording state
    _recordingManager.stateStream.listen((state) {
      print('Recording state: $state');
    });
  }
  
  Future<void> startRecording(String orderId) async {
    final success = await _recordingManager.startRecording(
      orderId: orderId,
    );
    
    if (success) {
      print('Recording started');
    }
  }
  
  Future<void> stopRecording() async {
    final result = await _recordingManager.stopRecording();
    
    if (result?.success == true) {
      print('Recording uploaded to: ${result!.cloudPath}');
    }
  }
}
```

## 🔧 Configuration

### Environment Variables

You can use `EnvironmentConfig` for easy setup:

```dart
await VoiceCallCore.initialize(
  CoreSDKConfig(
    appName: 'My App',
    sensitiveConfig: EnvironmentConfig(),
  ),
);
```

Required environment variables:
- `API_BASE_URL`: Your API base URL
- `WEBRTC_SOCKET_URL`: WebRTC socket endpoint
- `MEETING_SOCKET_URL`: Meeting socket endpoint
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `TURN_SERVER_URLS`: TURN server URLs (comma-separated)
- `TURN_USERNAME`: TURN server username
- `TURN_CREDENTIAL`: TURN server password

### Quality Settings

```dart
CoreSDKConfig(
  // ...
  qualityConfig: WebRTCQualityConfig.highQuality(), // or .balanced(), .lowBandwidth()
)
```

### Recording Settings

```dart
final recordingManager = VoiceCallCore.instance.createRecordingManager(
  config: CallRecordingConfig.highQualityConfig(), // or .defaultConfig(), .compactConfig()
);
```

## 🔒 Security

This package follows security best practices:

- ✅ No hardcoded URLs or credentials
- ✅ Configuration injection required
- ✅ Environment variable support
- ✅ Secure by default

**Important**: You MUST implement `SensitiveConfig` in your application. The package will throw errors if sensitive data is not provided.

## 📊 API Reference

### VoiceCallCore

Main SDK class:

```dart
class VoiceCallCore {
  static Future<void> initialize(CoreSDKConfig config);
  static bool get isInitialized;
  static VoiceCallCore get instance;
  
  CallRecordingManager createRecordingManager({CallRecordingConfig? config});
  CloudStorageManager createCloudStorageManager();
  CoreSDKConfig get config;
  
  static Future<void> dispose();
}
```

### CallRecordingManager

Recording functionality:

```dart
class CallRecordingManager {
  Future<bool> startRecording({String? orderId, String? customFileName});
  Future<CloudUploadResult?> stopRecording();
  Future<void> cancelRecording();
  
  Stream<CallRecordingState> get stateStream;
  bool get isRecording;
  Duration get recordingDuration;
  
  void dispose();
}
```

### CloudStorageManager

Cloud storage operations:

```dart
class CloudStorageManager {
  Future<CloudUploadResult> uploadCallRecording({
    required String localFilePath,
    String? orderId,
    String? customFileName,
  });
  
  Future<List<CloudRecordingInfo>> getOrderRecordings(String orderId);
  Future<StorageStats> getStorageStats();
  Future<bool> deleteCloudRecording(String cloudPath);
}
```

## 📱 Models

### CallEntity

```dart
class CallEntity {
  final String uuIdCall;
  final String orderId;
  final String roomId;
  final UserCall caller;
  final UserCall receiver;
}
```

### CallState

```dart
abstract class CallState {
  CallStateIdle();
  CallStateConnecting();
  CallStateConnected();
  CallStateEnded({String? reason});
  CallStateError(String message);
}
```

### ConnectionStats

```dart
class ConnectionStats {
  final double jitter;
  final double fractionLost;
  final double roundTripTime;
  final int packetsLost;
  final int totalPackets;
  
  double get qualityScore; // 0.0 to 1.0
  String get qualityText; // 'Excellent', 'Good', 'Fair', 'Poor'
  bool get isPoorConnection;
}
```

## 🧪 Example

See the [example](example/) directory for a complete implementation.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](https://github.com/YourOrg/voice_call_core/wiki)
- 🐛 [Issues](https://github.com/YourOrg/voice_call_core/issues)
- 💬 [Discussions](https://github.com/YourOrg/voice_call_core/discussions)

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.