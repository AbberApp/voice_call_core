/// Abstract interface for sensitive configuration data
/// 
/// This interface must be implemented by the consuming application
/// to provide all sensitive data like URLs, credentials, etc.
/// 
/// The Core Package contains NO hardcoded sensitive data.
abstract class SensitiveConfig {
  // API Endpoints
  String get apiBaseUrl;
  String get webhookEndpoint;
  String get webrtcSocketUrl;
  String get meetingSocketUrl;
  
  // WebRTC Servers
  List<String> get stunServers;
  List<Map<String, dynamic>> get turnServers;
  
  // Firebase Configuration
  String get firebaseProjectId;
  String get firebaseStorageBucket;
  
  // Optional API Keys
  String? get apiKey;
  String? get secretKey;
}

/// Exception thrown when configuration is invalid or missing
class ConfigException implements Exception {
  final String message;
  
  ConfigException(this.message);
  
  @override
  String toString() => 'ConfigException: $message';
}