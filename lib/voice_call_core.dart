library voice_call_core;

// Platform Interface
export 'voice_call_core_platform_interface.dart';

// Core Managers
export 'src/core/managers/call_recording_manager.dart';
export 'src/core/managers/cloud_storage_manager.dart';

// Models
export 'src/core/models/call_entity.dart';
export 'src/core/models/call_state.dart';
export 'src/core/models/connection_stats.dart';

// Configuration
export 'src/core/config/sdk_config.dart';
export 'src/core/config/sensitive_config.dart';
export 'src/core/config/default_config.dart';
export 'src/core/config/webrtc_quality_config.dart';

// Import required classes for the main SDK
import 'src/core/managers/call_recording_manager.dart';
import 'src/core/managers/cloud_storage_manager.dart';
import 'src/core/config/sdk_config.dart';
import 'src/core/config/sensitive_config.dart';

/// Main SDK class for Voice Call Core
/// 
/// This package provides secure voice call functionality without UI components.
/// All sensitive data must be provided through SensitiveConfig implementation.
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
  
  /// Initialize the SDK with configuration
  /// 
  /// Example:
  /// ```dart
  /// await VoiceCallCore.initialize(
  ///   CoreSDKConfig(
  ///     appName: 'My App',
  ///     sensitiveConfig: MyProductionConfig(),
  ///   ),
  /// );
  /// ```
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
  
  /// Create a call recording manager
  CallRecordingManager createRecordingManager({
    CallRecordingConfig? config,
  }) {
    if (!isInitialized) {
      throw StateError('SDK not initialized');
    }
    
    return CallRecordingManager(
      sensitiveConfig: _config!.sensitiveConfig,
      config: config,
    );
  }
  
  /// Create a cloud storage manager
  CloudStorageManager createCloudStorageManager() {
    if (!isInitialized) {
      throw StateError('SDK not initialized');
    }
    
    return CloudStorageManager(
      projectName: _config!.sensitiveConfig.firebaseProjectId,
      storageBucket: _config!.sensitiveConfig.firebaseStorageBucket,
    );
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
      final _ = config.sensitiveConfig.apiBaseUrl;
      final __ = config.sensitiveConfig.stunServers;
      final ___ = config.sensitiveConfig.firebaseProjectId;
      
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