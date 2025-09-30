import 'package:flutter/foundation.dart';

void logger(String msg) {
// Avoid importing dart:developer to keep package lightweight
  if (kDebugMode) {
    print(msg);
  }
}