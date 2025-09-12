import 'package:flutter/material.dart';
import 'package:voice_call_core/voice_call_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Voice Call Core Plugin
  await initializeVoiceCallCore();
  
  runApp(const MyApp());
}

Future<void> initializeVoiceCallCore() async {
  try {
    await VoiceCallCore.initialize(
      CoreSDKConfig(
        appName: 'Voice Call Core Example',
        sensitiveConfig: ExampleConfig(),
        qualityConfig: const WebRTCQualityConfig.highQuality(),
        enableRecording: true,
        enablePerformanceMonitoring: true,
      ),
    );
    print('✅ Voice Call Core initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Voice Call Core: $e');
  }
}

/// Example configuration for demonstration
/// In production, load these values from environment variables or secure storage
class ExampleConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://api.example.com';
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/webhooks/calls';
  
  @override
  String get webrtcSocketUrl => 'wss://ws.example.com/webrtc';
  
  @override
  String get meetingSocketUrl => 'wss://ws.example.com/meeting';
  
  @override
  List<String> get stunServers => [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
  ];
  
  @override
  List<Map<String, dynamic>> get turnServers => [
    {
      'urls': ['turn:openrelay.metered.ca:80'],
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ];
  
  @override
  String get firebaseProjectId => 'example-project-id';
  
  @override
  String get firebaseStorageBucket => 'example-project.appspot.com';
  
  @override
  String? get apiKey => 'example-api-key';
  
  @override
  String? get secretKey => null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Call Core Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Voice Call Core Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CallRecordingManager? _recordingManager;
  CloudStorageManager? _cloudManager;
  bool _isRecording = false;
  String _status = 'Ready';
  String _lastRecordingPath = '';

  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }

  void _initializeManagers() {
    if (VoiceCallCore.isInitialized) {
      _recordingManager = VoiceCallCore.instance.createRecordingManager(
        config: CallRecordingConfig.highQualityConfig(),
      );
      _cloudManager = VoiceCallCore.instance.createCloudStorageManager();
      setState(() {
        _status = 'Managers initialized';
      });
    } else {
      setState(() {
        _status = 'SDK not initialized';
      });
    }
  }

  Future<void> _startRecording() async {
    if (_recordingManager == null) return;
    
    try {
      setState(() {
        _status = 'Starting recording...';
      });
      
      final orderId = 'example-call-${DateTime.now().millisecondsSinceEpoch}';
      await _recordingManager!.startRecording(orderId: orderId);
      
      setState(() {
        _isRecording = true;
        _status = 'Recording started for order: $orderId';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_recordingManager == null) return;
    
    try {
      setState(() {
        _status = 'Stopping recording...';
      });
      
      final result = await _recordingManager!.stopRecording();
      
      setState(() {
        _isRecording = false;
        if (result?.success == true) {
          _lastRecordingPath = result!.localPath;
          _status = 'Recording saved: ${result.localPath}';
        } else {
          _status = 'Recording failed';
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _status = 'Failed to stop recording: $e';
      });
    }
  }

  Future<void> _uploadLastRecording() async {
    if (_cloudManager == null || _lastRecordingPath.isEmpty) return;
    
    try {
      setState(() {
        _status = 'Uploading to cloud...';
      });
      
      final orderId = 'example-upload-${DateTime.now().millisecondsSinceEpoch}';
      final result = await _cloudManager!.uploadCallRecording(
        localFilePath: _lastRecordingPath,
        orderId: orderId,
      );
      
      setState(() {
        if (result.success) {
          _status = 'Uploaded successfully: ${result.cloudPath}';
        } else {
          _status = 'Upload failed: ${result.error}';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Upload error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDK Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      VoiceCallCore.isInitialized ? 'Initialized ✅' : 'Not Initialized ❌',
                      style: TextStyle(
                        color: VoiceCallCore.isInitialized ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? null : _startRecording,
                            icon: const Icon(Icons.mic),
                            label: const Text('Start Recording'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? _stopRecording : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Recording'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _lastRecordingPath.isNotEmpty ? _uploadLastRecording : null,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload Last Recording'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ High-quality call recording'),
                    const Text('✅ Cloud storage integration'),
                    const Text('✅ Configurable audio quality'),
                    const Text('✅ Secure configuration system'),
                    const Text('✅ Multi-platform support'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}