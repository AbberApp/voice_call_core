import '../../../voice_call_core.dart';

abstract class CallSession {
  final Socket socketService;
  final CallEntity callEntity;

  CallSession({required this.socketService, required this.callEntity});

  void onCallAction(CallAction function);
}

typedef CallAction = void Function(CallState callState);
