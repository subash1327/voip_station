import 'dart:io';

import 'package:flutter/services.dart';

class ReplayKitChannel {
  static const String kReplayKitChannel =
      'io.livekit.example.flutter/replaykit-channel';

  static const MethodChannel _replayKitChannel =
  MethodChannel(kReplayKitChannel);

  static void listenMethodChannel() {
    _replayKitChannel.setMethodCallHandler((call) async {
      if (call.method == 'closeReplayKitFromNative') {
        print('closeReplayKitFromNative: ${call.arguments}');
      } else if (call.method == 'hasSampleBroadcast') {
        print('hasSampleBroadcast: ${call.arguments}');
      }
    });
  }

  static void startReplayKit() {
    if (!Platform.isIOS) return;
    _replayKitChannel.invokeMethod('startReplayKit');
  }

  static void closeReplayKit() {
    if (!Platform.isIOS) return;

    _replayKitChannel.invokeMethod('closeReplayKit');
  }
}