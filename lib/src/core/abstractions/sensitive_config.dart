abstract class SensitiveConfig {
  List<String> get stunServers;

  List<Map<String, dynamic>> get turnServers;
}

class ConfigException implements Exception {
  final String message;

  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
