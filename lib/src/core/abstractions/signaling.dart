import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../voice_call_core.dart';

abstract class Signaling {
  final Socket socketService;
  final CallEntity callEntity;

  Signaling({required this.socketService, required this.callEntity});

  void sendOffer(RTCSessionDescription sdp);

  void sendAnswer(RTCSessionDescription sdp);

  void sendIceCandidate(RTCIceCandidate candidate);

  /// Binding
  void onOffer(Function(RTCSessionDescription sdp) function);

  void onAnswer(Function(RTCSessionDescription sdp) function);

  void onIceCandidate(Function(RTCIceCandidate candidate) function);
}

// المكتبه مش هتعمل signaling server دي مسووليه المطور
// لكن نوفر واجهه hooks
// بكده المطور يقدر يوصّل socket/io أو Firebase أو أي backend بسهولة.
