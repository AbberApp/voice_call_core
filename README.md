# Voice Call Core Plugin

Flutter plugin for voice calls with WebRTC, recording, and cloud storage.

## Installation

```yaml
dependencies:
  voice_call_core:
    git:
      url: https://github.com/AbberApp/voice_call_core.git
      ref: voice-package
```

## Usage

```dart
import 'package:voice_call_core/voice_call_core.dart';

await VoiceCallCore.initialize(config);
```