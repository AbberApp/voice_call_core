import 'package:equatable/equatable.dart';

/// Base class for all call states
abstract class CallState extends Equatable {
  const CallState();
  
  @override
  List<Object?> get props => [];
}

/// Call is idle (not active)
class CallStateIdle extends CallState {
  const CallStateIdle();
  
  @override
  String toString() => 'CallStateIdle';
}

/// Call is connecting
class CallStateConnecting extends CallState {
  const CallStateConnecting();
  
  @override
  String toString() => 'CallStateConnecting';
}

/// Call is ringing
class CallStateRinging extends CallState {
  const CallStateRinging();
  
  @override
  String toString() => 'CallStateRinging';
}

/// Call is connected and active
class CallStateConnected extends CallState {
  const CallStateConnected();
  
  @override
  String toString() => 'CallStateConnected';
}

/// Call has ended
class CallStateEnded extends CallState {
  final String? reason;
  
  const CallStateEnded({this.reason});
  
  @override
  List<Object?> get props => [reason];
  
  @override
  String toString() => 'CallStateEnded${reason != null ? '($reason)' : ''}';
}

/// Call has an error
class CallStateError extends CallState {
  final String message;
  
  const CallStateError(this.message);
  
  @override
  List<Object?> get props => [message];
  
  @override
  String toString() => 'CallStateError($message)';
}

/// Call time warning (near time limit)
class CallStateTimeWarning extends CallState {
  const CallStateTimeWarning();
  
  @override
  String toString() => 'CallStateTimeWarning';
}

/// Call was declined
class CallStateDeclined extends CallState {
  const CallStateDeclined();
  
  @override
  String toString() => 'CallStateDeclined';
}

/// Call was not answered (timeout)
class CallStateTimeout extends CallState {
  const CallStateTimeout();
  
  @override
  String toString() => 'CallStateTimeout';
}

/// Enum for basic call status (for compatibility)
enum CallStatus {
  idle,
  connecting,
  ringing,
  connected,
  ended,
  error,
  declined,
  timeout,
  timeWarning,
}

/// Extension to convert CallState to CallStatus
extension CallStateExtension on CallState {
  CallStatus get status {
    switch (runtimeType) {
      case CallStateIdle:
        return CallStatus.idle;
      case CallStateConnecting:
        return CallStatus.connecting;
      case CallStateRinging:
        return CallStatus.ringing;
      case CallStateConnected:
        return CallStatus.connected;
      case CallStateEnded:
        return CallStatus.ended;
      case CallStateError:
        return CallStatus.error;
      case CallStateDeclined:
        return CallStatus.declined;
      case CallStateTimeout:
        return CallStatus.timeout;
      case CallStateTimeWarning:
        return CallStatus.timeWarning;
      default:
        return CallStatus.idle;
    }
  }
}