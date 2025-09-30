import '../../../voice_call_core.dart';

class CoreSDKConfig {
  final SensitiveConfig sensitiveConfig;
  final WebRTCQualityConfig qualityConfig;
  final bool enableRecording;
  final bool enablePerformanceMonitoring;

  const CoreSDKConfig({
    required this.sensitiveConfig,
    this.qualityConfig = const WebRTCQualityConfig.balanced(),
    this.enableRecording = true,
    this.enablePerformanceMonitoring = true,
  });

  /// Build ICE servers configuration from sensitive config
  Map<String, dynamic> get iceServers => _buildIceServers();

  /// Build audio constraints from quality config
  Map<String, dynamic> get audioConstraints => _buildAudioConstraints();

  Map<String, dynamic> _buildIceServers() {
    return {
      'iceServers': [
        {'urls': sensitiveConfig.stunServers},
        ...sensitiveConfig.turnServers,
      ],
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': qualityConfig.iceCandidatePoolSize,
      'iceConnectionReceiveTimeout': qualityConfig.iceTimeout,
      'iceInactivityTimeout': qualityConfig.iceTimeout,
      'continualGatheringPolicy': 'gather_continually',
      'iceRestartOnFailure': true,
    };
  }

  Map<String, dynamic> _buildAudioConstraints() {
    return {
      'video': false,
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': qualityConfig.sampleRate,
        'channelCount': 1,
        'latency': qualityConfig.latency,
        'maxBitrate': qualityConfig.maxBitrate,
        'minBitrate': qualityConfig.minBitrate,
      },
    };
  }
}
