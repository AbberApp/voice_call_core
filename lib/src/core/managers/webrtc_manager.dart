//# إدارة الـ RTCPeerConnection + MediaStream

import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:voice_call_core/voice_call_core.dart';

class WebRTCManager {
  final iceServers = <Map<String, dynamic>>[];

  RTCPeerConnection? _pc;

  final _connectionStatusController =
      StreamController<RTCPeerConnectionState>.broadcast();

  Stream<RTCPeerConnectionState> get onConnectionStateChanged =>
      _connectionStatusController.stream;

  VoiceCallCore get _flutterCalling => VoiceCallCore.instance;

  MediaStream? localStream, remoteStream;

  Future<void> init({bool audio = true, bool video = false}) async {
    logger('WebRTCManager: init');
    final mediaConstraints = <String, dynamic>{'audio': audio, 'video': video};
    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<void> createPeer(Signaling signaling) async {
    _pc = await createPeerConnection(_flutterCalling.config.iceServers);
    if (localStream != null) {
      localStream!.getTracks().forEach((t) {
        _pc?.addTrack(t, localStream!);
      });
    }

    _pc?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        logger('Remote stream received');
        remoteStream = event.streams[0];
      }
    };

    _pc!.onConnectionState = (state) {
      logger('Connection state changed: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _connectionStatusController.add(state);
        logger('✅ WebRTC P2P connection established successfully!');
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // TODO: handle disconnection -> reconnect
        _connectionStatusController.add(state);
      } else if ((state ==
                  RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
              state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) &&
          !_connectionStatusController.isClosed) {
        _connectionStatusController.add(state);
        logger('❌ WebRTC P2P connection failed!');
      }
    };

    _pc?.onIceCandidate = (RTCIceCandidate candidate) {
      // host app should listen via controller to send this candidate via signaling
      signaling.sendIceCandidate(candidate);
      logger('ON ICE candidate: ${candidate.candidate}');
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _pc!.createOffer();

    await _pc!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _pc!.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _pc?.addCandidate(candidate);
  }

  Future<void> dispose() async {
    await localStream?.dispose();
    await remoteStream?.dispose();
    await _pc?.close();
    await _connectionStatusController.close();
  }
}
