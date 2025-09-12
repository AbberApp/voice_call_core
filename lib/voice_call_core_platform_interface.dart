import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'voice_call_core_method_channel.dart';

abstract class VoiceCallCorePlatform extends PlatformInterface {
  /// Constructs a VoiceCallCorePlatform.
  VoiceCallCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static VoiceCallCorePlatform _instance = MethodChannelVoiceCallCore();

  /// The default instance of [VoiceCallCorePlatform] to use.
  ///
  /// Defaults to [MethodChannelVoiceCallCore].
  static VoiceCallCorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VoiceCallCorePlatform] when
  /// they register themselves.
  static set instance(VoiceCallCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
