abstract class SensitiveConfig {
  String get apiBaseUrl;
  List<String> get stunServers;
  String get webhookEndpoint;
  String get webrtcSocketUrl;
  String get meetingSocketUrl;

  List<Map<String, dynamic>> get turnServers;
}

class ConfigException implements Exception {
  final String message;

  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
