import '../core/abstractions/sensitive_config.dart';
import '../core/config/webrtc_quality_config.dart';

class WebrtcConfig {
  final List<Map<String, dynamic>> iceServers;

  WebrtcConfig({required this.iceServers});
}



