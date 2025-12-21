import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String name = 'WhatEat', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      if (error != null) {
        developer.log(
          message,
          name: name,
          error: error,
          stackTrace: stackTrace,
        );
        debugPrint('[$name] ERROR: $message\n$error\n$stackTrace');
      } else {
        developer.log(message, name: name);
        debugPrint('[$name] $message');
      }
    }
  }

  static void info(String message) => log(message, name: 'INFO');
  static void warning(String message) => log(message, name: 'WARN');
  static void error(String message, [Object? error, StackTrace? stackTrace]) => 
      log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
}
