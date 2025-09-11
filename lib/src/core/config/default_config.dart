import 'dart:io';
import 'sensitive_config.dart';

/// Default implementation that throws errors for all sensitive data
/// 
/// This ensures that applications MUST provide their own configuration
/// and prevents accidental use of hardcoded values.
class DefaultSensitiveConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => throw _configError('API_BASE_URL');
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/api/meetings/webhook/';
  
  @override
  String get webrtcSocketUrl => throw _configError('WEBRTC_SOCKET_URL');
  
  @override
  String get meetingSocketUrl => throw _configError('MEETING_SOCKET_URL');
  
  @override
  List<String> get stunServers => [
    // Only safe public STUN servers (no credentials needed)
    'stun:stun.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
    'stun:stun.mozilla.org',
  ];
  
  @override
  List<Map<String, dynamic>> get turnServers => throw _configError('TURN_SERVERS');
  
  @override
  String get firebaseProjectId => throw _configError('FIREBASE_PROJECT_ID');
  
  @override
  String get firebaseStorageBucket => throw _configError('FIREBASE_STORAGE_BUCKET');
  
  @override
  String? get apiKey => null;
  
  @override
  String? get secretKey => null;
  
  ConfigException _configError(String key) => ConfigException(
    'Production configuration required for $key. '
    'Implement SensitiveConfig in your application or use EnvironmentConfig.'
  );
}

/// Environment-based configuration that reads from environment variables
class EnvironmentConfig implements SensitiveConfig {
  final Map<String, String> _env;
  
  EnvironmentConfig([Map<String, String>? environment]) 
    : _env = environment ?? Platform.environment;
  
  @override
  String get apiBaseUrl => _getRequired('API_BASE_URL');
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/api/meetings/webhook/';
  
  @override
  String get webrtcSocketUrl => _getRequired('WEBRTC_SOCKET_URL');
  
  @override
  String get meetingSocketUrl => _getRequired('MEETING_SOCKET_URL');
  
  @override
  List<String> get stunServers {
    final custom = _env['STUN_SERVERS']?.split(',');
    return custom?.map((s) => s.trim()).toList() ?? _defaultStunServers;
  }
  
  @override
  List<Map<String, dynamic>> get turnServers {
    final urls = _env['TURN_SERVER_URLS']?.split(',');
    final username = _env['TURN_USERNAME'];
    final credential = _env['TURN_CREDENTIAL'];
    
    if (urls == null || username == null || credential == null) {
      return []; // Fallback to STUN only
    }
    
    return urls.map((url) => {
      'urls': [url.trim()],
      'username': username,
      'credential': credential,
    }).toList();
  }
  
  @override
  String get firebaseProjectId => _getRequired('FIREBASE_PROJECT_ID');
  
  @override
  String get firebaseStorageBucket => 
    _env['FIREBASE_STORAGE_BUCKET'] ?? '$firebaseProjectId.appspot.com';
  
  @override
  String? get apiKey => _env['API_KEY'];
  
  @override
  String? get secretKey => _env['SECRET_KEY'];
  
  String _getRequired(String key) {
    final value = _env[key];
    if (value == null || value.isEmpty) {
      throw ConfigException('Required environment variable $key is not set');
    }
    return value;
  }
  
  static const List<String> _defaultStunServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
    'stun:stun.mozilla.org',
  ];
}