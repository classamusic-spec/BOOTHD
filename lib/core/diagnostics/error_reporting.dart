import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'safe_log.dart';

/// Sends every uncaught error to [SafeLog] (AC-1007): framework errors
/// (build, layout, gestures) and errors no code awaited. Nothing else
/// reaches the device log. Guests never see an error's text: the screens
/// catch what they expect, and release builds draw a widget that failed to
/// build as a plain grey area.
void reportErrorsSafely() {
  FlutterError.onError = (details) => SafeLog.error(
    details.exception,
    details.stack,
    context: details.context?.toDescription(),
  );
  PlatformDispatcher.instance.onError = (error, stack) {
    SafeLog.error(error, stack, context: 'uncaught');
    return true;
  };
}
