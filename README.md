# Voice Call Core Plugin

**PRIVATE PLUGIN FOR ABBER APP ONLY**

A comprehensive Flutter plugin for Abber App voice calls with WebRTC, recording, and cloud storage support.

⚠️ **This plugin is proprietary and for internal use only. Not for public distribution.**

## Features

- 🎙️ **High-Quality Voice Calls** - WebRTC-based voice communication
- 📱 **CallKit Integration** - Native iOS CallKit and Android ConnectionService
- 🎵 **Call Recording** - Automatic call recording with configurable quality
- ☁️ **Cloud Storage** - Firebase Storage integration for recordings
- 🔧 **Configurable** - Flexible configuration system for different environments
- 🔒 **Secure** - No hardcoded sensitive data, configuration injection
- 📊 **Performance Monitoring** - Built-in performance tracking
- 🌐 **Multi-Platform** - Android, iOS, and Web support

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  voice_call_core: ^1.0.0
```

## Quick Start

### 1. Initialize the Plugin

```dart
import 'package:voice_call_core/voice_call_core.dart';

// Create your configuration
class MyVoiceConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://your-api.com';
  
  @override
  String get firebaseProjectId => 'your-project-id';
  
  @override
  String get firebaseStorageBucket => 'your-bucket.appspot.com';
  
  @override
  List<String> get stunServers => [
    'stun:stun.l.google.com:19302',
  ];
  
  // ... implement other required methods
}

// Initialize in your main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await VoiceCallCore.initialize(
    CoreSDKConfig(
      appName: 'My App',
      sensitiveConfig: MyVoiceConfig(),
      qualityConfig: const WebRTCQualityConfig.highQuality(),
      enableRecording: true,
      enablePerformanceMonitoring: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Create Managers

```dart
// Create recording manager
final recordingManager = VoiceCallCore.instance.createRecordingManager(
  config: CallRecordingConfig.highQualityConfig(),
);

// Create cloud storage manager
final cloudManager = VoiceCallCore.instance.createCloudStorageManager();
```

### 3. Start Recording

```dart
// Start recording a call
await recordingManager.startRecording(orderId: 'call-123');

// Stop recording and upload to cloud
final result = await recordingManager.stopRecording();
if (result?.success == true) {
  print('Recording uploaded: ${result!.cloudPath}');
}
```

## Configuration

### SensitiveConfig Interface

Implement the `SensitiveConfig` interface to provide your app's sensitive data:

```dart
class ProductionConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://api.yourapp.com';
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/webhooks/calls';
  
  @override
  String get webrtcSocketUrl => 'wss://ws.yourapp.com/webrtc';
  
  @override
  List<String> get stunServers => [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];
  
  @override
  List<Map<String, dynamic>> get turnServers => [
    {
      'urls': ['turn:your-turn-server.com:3478'],
      'username': 'your-username',
      'credential': 'your-credential',
    },
  ];
  
  @override
  String get firebaseProjectId => 'your-firebase-project';
  
  @override
  String get firebaseStorageBucket => 'your-bucket.appspot.com';
  
  @override
  String? get apiKey => 'your-api-key';
  
  @override
  String? get secretKey => null;
}
```

### WebRTC Quality Presets

Choose from predefined quality configurations:

```dart
// High quality (48kHz, 128kbps)
const WebRTCQualityConfig.highQuality()

// Standard quality (32kHz, 64kbps)
const WebRTCQualityConfig.standardQuality()

// Low quality (16kHz, 32kbps)
const WebRTCQualityConfig.lowQuality()

// Custom quality
WebRTCQualityConfig.custom(
  sampleRate: 44100,
  maxBitrate: 96000,
  minBitrate: 24000,
)
```

## Platform Setup

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name=\"android.permission.INTERNET\" />
<uses-permission android:name=\"android.permission.RECORD_AUDIO\" />
<uses-permission android:name=\"android.permission.MODIFY_AUDIO_SETTINGS\" />
<uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\" />
```

### iOS

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calls</string>
```

### Web

No additional setup required for web platform.

## Advanced Usage

### Custom Recording Configuration

```dart
final recordingManager = VoiceCallCore.instance.createRecordingManager(
  config: CallRecordingConfig(
    quality: RecordingQuality.high,
    format: RecordingFormat.aac,
    enableAutoUpload: true,
    deleteLocalAfterUpload: true,
    maxDurationMinutes: 30,
  ),
);
```

### Cloud Storage Operations

```dart
final cloudManager = VoiceCallCore.instance.createCloudStorageManager();

// Upload existing file
final uploadResult = await cloudManager.uploadCallRecording(
  localFilePath: '/path/to/recording.aac',
  orderId: 'call-123',
  customFileName: 'important-call.aac',
);

// Get recordings for an order
final recordings = await cloudManager.getOrderRecordings('call-123');

// Delete recording
await cloudManager.deleteCloudRecording(recordings.first.cloudPath);
```

### Performance Monitoring

```dart
// Monitor call quality
recordingManager.statsStream.listen((stats) {
  print('Audio level: ${stats.audioLevel}');
  print('Connection quality: ${stats.connectionQuality}');
});
```

## Error Handling

```dart
try {
  await VoiceCallCore.initialize(config);
} on ConfigException catch (e) {
  print('Configuration error: $e');
} catch (e) {
  print('Initialization failed: $e');
}
```

## Security Best Practices

1. **Never hardcode sensitive data** - Use environment variables or secure storage
2. **Implement SensitiveConfig properly** - Validate all configuration values
3. **Use HTTPS/WSS** - Ensure all network communication is encrypted
4. **Validate API responses** - Don't trust external data
5. **Handle permissions properly** - Request permissions before using features

## Example App

See the `example/` directory for a complete implementation showing:

- Plugin initialization
- Call recording workflow
- Cloud storage integration
- Error handling
- Platform-specific setup

## Contributing

**This is a private plugin. No external contributions accepted.**

For internal development:
1. Contact Abber App development team
2. Get authorization for modifications
3. Follow internal development guidelines

## License

**PROPRIETARY SOFTWARE - All rights reserved by Abber App.**

## Support

**Internal support only.** Contact Abber App development team for assistance.