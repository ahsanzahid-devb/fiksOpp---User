import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html/parser.dart' as html_parser;

import 'fcm_payload_utils.dart';

String _parseHtmlSnippet(String? s) {
  if (s == null || s.isEmpty) return '';
  try {
    return html_parser.parse(s).body?.text ?? s;
  } catch (_) {
    return s;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showSystemTrayNotification(message);
}

Future<void> _showSystemTrayNotification(RemoteMessage message) async {
  logFcmInboundDiagnostics(message, phase: 'background_isolate');
  final display = fcmResolveDisplayText(message);
  if (!display.hasContent) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM|inbound] background: no tray notification (no display text)');
    }
    return;
  }

  final title = display.title.isEmpty ? 'FiksOpp' : display.title;
  final body = _parseHtmlSnippet(display.body.isEmpty ? ' ' : display.body);
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

  const androidInit = AndroidInitializationSettings(
    '@drawable/ic_stat_ic_notification',
  );
  const darwinInit = DarwinInitializationSettings(
    defaultPresentAlert: true,
    defaultPresentSound: true,
    defaultPresentBadge: true,
    defaultPresentBanner: true,
    defaultPresentList: true,
  );
  await plugin.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    ),
  );

  final androidDetails = AndroidNotificationDetails(
    androidChannel.id,
    androidChannel.name,
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    icon: '@drawable/ic_stat_ic_notification',
  );
  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    presentList: true,
  );

  await plugin.show(
    message.hashCode,
    title.isEmpty ? 'FiksOpp' : title,
    body.isEmpty ? ' ' : body,
    NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    ),
    payload: jsonEncode(message.data),
  );
}
