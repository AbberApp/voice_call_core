import 'dart:async';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../voice_call_core.dart';

class CallController {
  final WebRTCManager _webrtc = WebRTCManager();
  final Signaling signaling;
  final CallSession callSessionService;

  final _stateController = StreamController<CallState>.broadcast();
  CallState _state = CallState.idle;

  Stream<CallState> get onCallStateChanged => _stateController.stream;

  final _localStreamController = StreamController<MediaStream?>.broadcast();

  Stream<MediaStream?> get onLocalStream => _localStreamController.stream;

  bool _isInitialized = false;

  CallController({required this.signaling, required this.callSessionService}) {
    _bindSignaling();
    _bindCallSession();
  }

  bool isCaller = false;

  void _bindSignaling() {
    isCaller = signaling.callEntity.roomId == signaling.callEntity.currentUser;
    signaling.onOffer((offer) {
      _handleIncomingOffer(offer);
    });
    signaling.onAnswer((answer) {
      _webrtc.setRemoteDescription(answer);
    });
    signaling.onIceCandidate((candidate) {
      _webrtc.addIceCandidate(candidate);
    });
  }

  void _bindCallSession() {
    callSessionService.onCallAction((CallState state) {
      if (state == CallState.joined && isCaller) _onJoinedOtherUser();
      _setState(state);
    });
    _webrtc.onConnectionStateChanged.listen((state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setState(CallState.connected);
      }
    });
  }

  void _onJoinedOtherUser() => _createOffer();

  void _setState(CallState s) {
    _state = s;
    _stateController.add(s);
    logger('NOW STATE $_state');
  }

  Future<void> initializeWebRTC() async {
    if (_isInitialized) return;
    _setState(CallState.initializing);
    await _webrtc.init(audio: true, video: false);
    _localStreamController.add(_webrtc.localStream);
    _isInitialized = true;
    _setState(CallState.idle);
    signaling.socketService.connect();
    callSessionService.socketService.connect();
    _setState(CallState.connecting);
    await _webrtc.createPeer(signaling);
  }

  void _createOffer() async {
    logger('CREATE OFFER .....');
    final offer = await _webrtc.createOffer();
    signaling.sendOffer(offer);
  }

  void dispose() {
    _stateController.close();
    _localStreamController.close();
    _webrtc.dispose();
    signaling.socketService.dispose();
    callSessionService.socketService.dispose();
  }

  Future<void> _handleIncomingOffer(RTCSessionDescription offer) async {
    await _webrtc.setRemoteDescription(offer);
    final answer = await _webrtc.createAnswer();
    signaling.sendAnswer(answer);
  }
}
