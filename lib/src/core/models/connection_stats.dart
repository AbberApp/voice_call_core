import 'package:equatable/equatable.dart';

/// Connection quality statistics
class ConnectionStats extends Equatable {
  final double jitter;
  final double fractionLost;
  final double roundTripTime;
  final int packetsLost;
  final int totalPackets;
  final DateTime timestamp;
  
  const ConnectionStats({
    required this.jitter,
    required this.fractionLost,
    required this.roundTripTime,
    required this.packetsLost,
    required this.totalPackets,
    required this.timestamp,
  });
  
  /// Calculate connection quality score (0.0 to 1.0)
  double get qualityScore {
    // Lower jitter and packet loss = better quality
    final jitterScore = (100 - jitter.clamp(0, 100)) / 100;
    final lossScore = (1 - fractionLost.clamp(0, 1));
    final rttScore = (500 - (roundTripTime * 1000).clamp(0, 500)) / 500;
    
    return (jitterScore + lossScore + rttScore) / 3;
  }
  
  /// Get quality as text
  String get qualityText {
    final score = qualityScore;
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Poor';
  }
  
  /// Check if connection is poor
  bool get isPoorConnection {
    return jitter > 100 || fractionLost > 0.05 || roundTripTime > 0.5;
  }
  
  @override
  List<Object?> get props => [
    jitter,
    fractionLost,
    roundTripTime,
    packetsLost,
    totalPackets,
    timestamp,
  ];
  
  @override
  String toString() {
    return 'ConnectionStats{quality: $qualityText, jitter: ${jitter.toStringAsFixed(1)}ms, '
           'loss: ${(fractionLost * 100).toStringAsFixed(1)}%, '
           'rtt: ${(roundTripTime * 1000).toStringAsFixed(0)}ms}';
  }
}