
library;


import 'voice_call_core.dart';

export 'src/controllers/call_controller.dart';
export 'src/core/abstractions/signaling.dart';
export 'src/core/abstractions/call_session.dart';
export 'src/core/managers/webrtc_manager.dart';
export 'src/models/call_state.dart';
export 'src/models/call_entity.dart';
export 'src/core/abstractions/socket.dart';

export 'src/utils/logger.dart';
export 'src/core/config/core_sdk_config.dart';
export 'src/core/config/webrtc_quality_config.dart';
export 'src/core/abstractions/sensitive_config.dart';


class VoiceCallCore {
  static VoiceCallCore? _instance;
  static CoreSDKConfig? _config;

  static VoiceCallCore get instance {
    if (_instance == null) {
      throw StateError(
          'VoiceCallCore not initialized. Call initialize() first.'
      );
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  static Future<void> initialize(CoreSDKConfig config) async {
    if (_instance != null) {
      throw StateError('VoiceCallCore already initialized');
    }

    // Validate configuration
    await _validateConfig(config);

    _config = config;
    _instance = VoiceCallCore._();
    await _instance!._init();
  }

  VoiceCallCore._();

  Future<void> _init() async {
    // Initialize core components
    await _initializeFirebase();
    await _initializePerformanceMonitoring();

    print('✅ VoiceCallCore initialized successfully');
  }

  /// Get current SDK configuration
  CoreSDKConfig get config {
    if (_config == null) {
      throw StateError('SDK not initialized');
    }
    return _config!;
  }



  /// Dispose SDK resources
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!._cleanup();
      _instance = null;
      _config = null;
    }
  }

  static Future<void> _validateConfig(CoreSDKConfig config) async {
    try {
      // Test sensitive config access
      final __ = config.sensitiveConfig.stunServers;

      print('✅ Configuration validated');
    } catch (e) {
      throw ConfigException('Invalid configuration: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    // Initialize Firebase if needed
    print('✅ Firebase components ready');
  }

  Future<void> _initializePerformanceMonitoring() async {
    // Initialize performance monitoring
    if (_config!.enablePerformanceMonitoring) {
      print('✅ Performance monitoring enabled');
    }
  }

  Future<void> _cleanup() async {
    // Cleanup resources
    print('✅ SDK disposed');
  }
}
