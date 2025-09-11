import 'package:equatable/equatable.dart';

/// Main call entity containing all call information
class CallEntity extends Equatable {
  /// Unique call identifier
  final String uuIdCall;
  
  /// Order identifier for business logic
  final String orderId;
  
  /// Room identifier for WebRTC connection
  final String roomId;
  
  /// Caller information
  final UserCall caller;
  
  /// Receiver information
  final UserCall receiver;
  
  const CallEntity({
    required this.uuIdCall,
    required this.orderId,
    required this.roomId,
    required this.caller,
    required this.receiver,
  });
  
  /// Create CallEntity from JSON (for incoming calls)
  factory CallEntity.fromJson(Map<String, dynamic> json) {
    final extra = json['extra'] as Map<String, dynamic>? ?? {};
    
    return CallEntity(
      uuIdCall: json['id'] ?? '',
      orderId: extra['order_id']?.toString() ?? 'unknown',
      roomId: extra['room_id'] ?? '',
      caller: UserCall(
        name: json['nameCaller'] ?? '',
        profileImage: json['avatar'] ?? extra['image'] ?? '',
      ),
      receiver: const UserCall(name: '', profileImage: ''),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': uuIdCall,
      'nameCaller': caller.name,
      'avatar': caller.profileImage,
      'extra': {
        'order_id': orderId,
        'room_id': roomId,
        'image': caller.profileImage,
      },
    };
  }
  
  /// Create a copy with modified fields
  CallEntity copyWith({
    String? uuIdCall,
    String? orderId,
    String? roomId,
    UserCall? caller,
    UserCall? receiver,
  }) {
    return CallEntity(
      uuIdCall: uuIdCall ?? this.uuIdCall,
      orderId: orderId ?? this.orderId,
      roomId: roomId ?? this.roomId,
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
    );
  }
  
  @override
  List<Object?> get props => [uuIdCall, orderId, roomId, caller, receiver];
  
  @override
  String toString() {
    return 'CallEntity{uuIdCall: $uuIdCall, orderId: $orderId, roomId: $roomId, '
           'caller: ${caller.toString()}, receiver: ${receiver.toString()}}';
  }
}

/// User information for calls
class UserCall extends Equatable {
  final String name;
  final String profileImage;
  
  const UserCall({
    required this.name,
    required this.profileImage,
  });
  
  @override
  List<Object?> get props => [name, profileImage];
  
  @override
  String toString() => 'UserCall{name: $name, profileImage: $profileImage}';
}