# Integration Guide

## كيفية استخدام Package في التطبيق الحالي

### الخطوة 1: إضافة Package للتطبيق الحالي

في `pubspec.yaml` للتطبيق الحالي:

```yaml
dependencies:
  # ... dependencies أخرى
  voice_call_core:
    path: ../voice_call_core  # مسار الـ package المحلي
```

### الخطوة 2: إنشاء Configuration للتطبيق

إنشاء ملف `lib/config/voice_call_config.dart`:

```dart
import 'package:voice_call_core/voice_call_core.dart';
import 'dart:io';

class ProductionConfig implements SensitiveConfig {
  @override
  String get apiBaseUrl => 'https://api.yourapp.com';
  
  @override
  String get webhookEndpoint => '$apiBaseUrl/api/meetings/webhook/';
  
  @override
  String get webrtcSocketUrl => 'wss://ws.yourapp.com/webrtc';
  
  @override
  String get meetingSocketUrl => 'wss://ws.yourapp.com/meeting';
  
  @override
  List<String> get stunServers => [
    'stun:stun.yourapp.com:3478',
    'stun:stun.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
  ];
  
  @override
  List<Map<String, dynamic>> get turnServers => [
    {
      'urls': ['turn:turn.yourapp.com:3478'],
      'username': Platform.environment['TURN_USERNAME'] ?? 'your_turn_user',
      'credential': Platform.environment['TURN_CREDENTIAL'] ?? 'secure_password',
    }
  ];
  
  @override
  String get firebaseProjectId => 'your-production-project';
  
  @override
  String get firebaseStorageBucket => 'your-production-project.appspot.com';
  
  @override
  String? get apiKey => Platform.environment['YOUR_API_KEY'];
  
  @override
  String? get secretKey => Platform.environment['YOUR_SECRET_KEY'];
}
```

### الخطوة 3: تحديث main.dart

```dart
import 'package:voice_call_core/voice_call_core.dart';
import 'config/voice_call_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Voice Call Core
  await VoiceCallCore.initialize(
    CoreSDKConfig(
      appName: 'عبر',
      sensitiveConfig: ProductionConfig(),
      qualityConfig: const WebRTCQualityConfig.highQuality(),
      enableRecording: true,
      enablePerformanceMonitoring: true,
    ),
  );
  
  // ... باقي initialization
  runApp(MyApp());
}
```

### الخطوة 4: تحديث CallCubit

```dart
import 'package:voice_call_core/voice_call_core.dart';

class CallCubit extends Cubit<CallState> {
  CallCubit() : super(CallInitial());

  // استبدال VoiceManager بـ Core Package
  CallRecordingManager? _recordingManager;
  CloudStorageManager? _cloudManager;
  
  void initializeCall() {
    // إنشاء managers من الـ Core Package
    _recordingManager = VoiceCallCore.instance.createRecordingManager(
      config: CallRecordingConfig.highQualityConfig(),
    );
    
    _cloudManager = VoiceCallCore.instance.createCloudStorageManager();
    
    // الاستماع لحالة التسجيل
    _recordingManager!.stateStream.listen((state) {
      // تحديث UI حسب حالة التسجيل
      emit(RecordingStateChanged(state));
    });
  }
  
  void makeCall(VoiceCallEntity voiceCall) async {
    // تحويل VoiceCallEntity إلى CallEntity
    final callEntity = CallEntity(
      uuIdCall: voiceCall.uuIdCall,
      orderId: voiceCall.orderId,
      roomId: voiceCall.roomId,
      caller: UserCall(
        name: voiceCall.caller.name,
        profileImage: voiceCall.caller.profileImage,
      ),
      receiver: UserCall(
        name: voiceCall.receiver.name,
        profileImage: voiceCall.receiver.profileImage,
      ),
    );
    
    // بدء التسجيل تلقائياً
    if (_recordingManager != null) {
      await _recordingManager!.startRecording(
        orderId: callEntity.orderId,
      );
    }
    
    // ... باقي منطق المكالمة
  }
  
  void endCall() async {
    // إيقاف التسجيل ورفعه للسحابة
    if (_recordingManager != null && _recordingManager!.isRecording) {
      final result = await _recordingManager!.stopRecording();
      
      if (result?.success == true) {
        print('تم رفع التسجيل للسحابة: ${result!.cloudPath}');
      }
    }
    
    // ... باقي منطق إنهاء المكالمة
  }
  
  @override
  Future<void> close() {
    _recordingManager?.dispose();
    return super.close();
  }
}
```

### الخطوة 5: تحديث UI Components

الـ UI يبقى كما هو، فقط تحديث الـ state management:

```dart
// في ongoing_call_screen.dart
BlocBuilder<CallCubit, CallState>(
  builder: (context, state) {
    if (state is RecordingStateChanged) {
      // عرض حالة التسجيل
      return RecordingIndicator(state: state.recordingState);
    }
    
    // ... باقي UI
    return CallInterface();
  },
)
```

## الفوائد من التحويل

### 1. فصل المنطق عن UI
- الـ Core Package يحتوي على المنطق الأساسي فقط
- UI منفصل تماماً ويمكن تخصيصه
- سهولة الاختبار والصيانة

### 2. إعادة الاستخدام
- يمكن استخدام نفس الـ Core في مشاريع أخرى
- UI مختلف لكل مشروع
- تحديث مركزي للمنطق الأساسي

### 3. الأمان
- لا توجد بيانات حساسة في الـ Package
- كل تطبيق يدير بياناته الحساسة
- مرونة في التكوين

### 4. سهولة الصيانة
- تحديثات منفصلة للـ Core والـ UI
- اختبارات منفصلة
- تطوير منفصل للفرق

## الخطوات التالية

1. **اختبار التكامل**: تشغيل التطبيق مع الـ Core Package
2. **نقل باقي المكونات**: WebRTC، CallKit، إلخ
3. **تحسين الأداء**: optimizations للإنتاج
4. **إضافة المراقبة**: performance monitoring
5. **التوثيق**: documentation شامل

## ملاحظات مهمة

- الـ Package حالياً يحتوي على Recording وCloud Storage فقط
- باقي المكونات (WebRTC، CallKit) ستضاف تدريجياً
- UI يبقى في التطبيق الأصلي
- Configuration يجب أن يكون آمن ومنفصل