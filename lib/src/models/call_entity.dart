import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../voice_call_core.dart';


class CallEntity<T> extends Equatable {
  /// For id calling
  final String uuIdCall;

  /// For status order
  final String orderId;

  /// For sockets
  final String roomId;

  /// For a seller and buyer
  final UserCall caller, receiver;

  final T? currentUser;

   const CallEntity({
    required this.caller,
    required this.receiver,
    required this.uuIdCall,
    required this.orderId,
    required this.roomId,
    this.currentUser,
  });

  /// [VoiceCallEntity.fromJson(json)]
  /// Only Android for incoming call by receiver
  factory CallEntity.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = _confirmExtraData(json);
    return CallEntity(
      uuIdCall: json['id'] ?? '',
      caller: UserCall(name: json['nameCaller'], profileImage: extra['image']),
      receiver: const UserCall(name: '', profileImage: 'image'),
      orderId: extra['order_id']?.toString() ?? 'unknown',
      roomId: extra['room_id'],
    );
  }

  @override
  List<Object?> get props => [uuIdCall, orderId, roomId, caller, receiver];

  @override
  String toString() {
    return 'CallEntity {uuIdCall: $uuIdCall, orderId: $orderId, roomId: $roomId, caller: ${caller.toString()}, receiver: ${receiver.toString()}}';
  }

  CallEntity copyWith({
    String? uuIdCall,
    String? orderId,
    String? roomId,
    UserCall? caller,
    UserCall? receiver,
    Map<String, dynamic>? extra,
  }) {
    return CallEntity(
      uuIdCall: uuIdCall ?? this.uuIdCall,
      orderId: orderId ?? this.orderId,
      roomId: roomId ?? this.roomId,
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
    );
  }
}

class UserCall extends Equatable {
  final String name;
  final String profileImage;

  const UserCall({required this.name, required this.profileImage});

  factory UserCall.fromJson(Map<String, dynamic> json) {
    return UserCall(
      name: json['name'] ?? '',
      profileImage: json['profileImage'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, profileImage];

  @override
  String toString() {
    return 'UserCall{name: $name, profileImage: $profileImage}';
  }

  UserCall copyWith({
    String? name,
    String? profileImage,
  }) {
    return UserCall(
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

Map<String, dynamic> _confirmExtraData(Map<String, dynamic> payload) {
  Map<String, dynamic> data = {};
  try {
    if (payload['extra'] is String) {
      final String fixedJson = payload['extra']
          .replaceAll("'", '"')
          .replaceAll('False', 'false')
          .replaceAll('True', 'true');
      data = jsonDecode(fixedJson);
    }
  } catch (e) {
    logger('Failed to parse extra data: $e');
  }
  return data;
}
