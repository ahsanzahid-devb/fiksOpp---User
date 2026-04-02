import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html/parser.dart' as html_parser;

String _parseHtmlSnippet(String? s) {
  if (s == null || s.isEmpty) return '';
  try {
    return html_parser.parse(s).body?.text ?? s;
  } catch (_) {
    return s;
  }
}

/// Top-level handler for FCM when app is terminated or in background (Android).
/// Must not import `main.dart` to keep the isolate lean and avoid cycles.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showSystemTrayNotification(message);
}

Future<void> _showSystemTrayNotification(RemoteMessage message) async {
  Map<String, dynamic> additional = const {};
  final additionalRaw = message.data['additional_data'];
  if (additionalRaw is String && additionalRaw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(additionalRaw);
      if (decoded is Map<String, dynamic>) additional = decoded;
    } catch (_) {}
  }

  final title = message.notification?.title?.trim().isNotEmpty == true
      ? message.notification!.title!.trim()
      : (message.data['title']?.toString() ??
          message.data['gcm.notification.title']?.toString() ??
          additional['type']?.toString() ??
          'FiksOpp');

  final bodyRaw = message.notification?.body?.trim().isNotEmpty == true
      ? message.notification!.body!.trim()
      : (message.data['body']?.toString() ??
          message.data['message']?.toString() ??
          message.data['gcm.notification.body']?.toString() ??
          additional['message']?.toString() ??
          '');

  if (title.isEmpty && bodyRaw.isEmpty) return;

  final body = _parseHtmlSnippet(bodyRaw);
  final plugin = FlutterLocalNotificationsPlugin();

  const androidChannel = AndroidNotificationChannel(
    'notification',
    'Notification',
    importance: Importance.high,
    enableLights: true,
    playSound: true,
    showBadge: true,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  const androidInit = AndroidInitializationSettings('@drawable/ic_stat_ic_notification');
  const darwinInit = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit),
  );

  final androidDetails = AndroidNotificationDetails(
    androidChannel.id,
    androidChannel.name,
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    icon: '@drawable/ic_stat_ic_notification',
  );
  const darwinDetails = DarwinNotificationDetails();

  await plugin.show(
    message.hashCode,
    title.isEmpty ? 'FiksOpp' : title,
    body.isEmpty ? ' ' : body,
    NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    ),
  );

  if (Platform.isIOS) {
    // iOS killed-state delivery often uses APNs payload; local show is best-effort for data-only.
  }
}
