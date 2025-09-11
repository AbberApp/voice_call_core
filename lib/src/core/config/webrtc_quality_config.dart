/// Configuration for WebRTC audio quality settings
class WebRTCQualityConfig {
  final int sampleRate;
  final double latency;
  final int maxBitrate;
  final int minBitrate;
  final int iceCandidatePoolSize;
  final int iceTimeout;
  
  const WebRTCQualityConfig({
    required this.sampleRate,
    required this.latency,
    required this.maxBitrate,
    required this.minBitrate,
    required this.iceCandidatePoolSize,
    required this.iceTimeout,
  });
  
  /// High quality configuration for excellent network conditions
  const WebRTCQualityConfig.highQuality()
    : sampleRate = 48000,
      latency = 0.02,
      maxBitrate = 128000,
      minBitrate = 64000,
      iceCandidatePoolSize = 15,
      iceTimeout = 20000;
  
  /// Balanced configuration for normal network conditions
  const WebRTCQualityConfig.balanced()
    : sampleRate = 32000,
      latency = 0.03,
      maxBitrate = 96000,
      minBitrate = 32000,
      iceCandidatePoolSize = 10,
      iceTimeout = 30000;
  
  /// Low bandwidth configuration for poor network conditions
  const WebRTCQualityConfig.lowBandwidth()
    : sampleRate = 16000,
      latency = 0.05,
      maxBitrate = 64000,
      minBitrate = 16000,
      iceCandidatePoolSize = 5,
      iceTimeout = 40000;
}