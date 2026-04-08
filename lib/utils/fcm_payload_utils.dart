import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

/// Parses [data]['additional_data'] when it is a JSON string (FCM data values are strings).
Map<String, dynamic> fcmParseAdditionalData(Map<String, dynamic> data) {
  final raw = data['additional_data'];
  if (raw is! String || raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return const {};
}

void _absorbJsonStringInto(Map<String, dynamic> out, String? raw) {
  if (raw == null) return;
  final s = raw.trim();
  if (s.isEmpty || !s.startsWith('{')) return;
  try {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      out.addAll(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {}
}

/// Merges JSON blobs the backend may send as FCM string values (Laravel / admin panels
/// often mirror in-app notification `data` inside `additional_data` or `payload`).
Map<String, dynamic> fcmMergedDataMap(Map<String, dynamic> data) {
  final merged = <String, dynamic>{};
  _absorbJsonStringInto(merged, data['additional_data']?.toString());
  _absorbJsonStringInto(merged, data['payload']?.toString());
  _absorbJsonStringInto(merged, data['notification_data']?.toString());
  _absorbJsonStringInto(merged, data['custom_data']?.toString());
  for (final e in data.entries) {
    final v = e.value?.toString();
    if (v == null || v.length < 3) continue;
    if (v.startsWith('{') && e.key != 'additional_data') {
      _absorbJsonStringInto(merged, v);
    }
  }
  return merged;
}

String _stripHtmlToPlain(String s) {
  if (s.isEmpty) return s;
  try {
    final plain = html_parser.parse(s).body?.text;
    if (plain == null || plain.trim().isEmpty) return s;
    return plain.trim();
  } catch (_) {
    return s;
  }
}

/// User-facing title strings (e.g. "New Bid Received") vs machine ids (`provider_send_bid`).
bool _looksLikeUserFacingTitle(String t) {
  final s = t.trim();
  if (s.isEmpty) return false;
  if (s.contains(' ')) return true;
  if (RegExp(r'^[a-z0-9_]+$').hasMatch(s)) return false;
  return s.length >= 6;
}

String? _lookupCi(Map<String, dynamic> map, List<String> keys) {
  if (map.isEmpty) return null;
  final byLower = <String, dynamic>{};
  for (final e in map.entries) {
    byLower[e.key.toLowerCase()] = e.value;
  }
  for (final k in keys) {
    final v = byLower[k.toLowerCase()];
    final s = v?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}

String? _stringFromData(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    final v = data[k]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

/// Title/body for showing a local notification (iOS foreground + background isolate).
class FcmDisplayText {
  final String title;
  final String body;

  const FcmDisplayText(this.title, this.body);

  bool get hasContent => title.isNotEmpty || body.isNotEmpty;
}

/// Resolves human-readable title/body from FCM [notification] + [data] + decoded [additional_data].
///
/// Chat works on iOS because the server sends a `notification` { title, body }. Many booking/bid
/// payloads are data-only or store text only under `additional_data`; Android still shows them more
/// reliably. This resolver reads common backend key shapes so local notifications can display.
FcmDisplayText fcmResolveDisplayText(RemoteMessage message) {
  final data = message.data;
  final merged = fcmMergedDataMap(data);
  final n = message.notification;

  String title = '';
  if (n?.title != null && n!.title!.trim().isNotEmpty) {
    title = n.title!.trim();
  } else {
    title = _stringFromData(data, [
          'title',
          'gcm.notification.title',
          'notification_title',
          'subject',
        ]) ??
        _lookupCi(merged, [
          'title',
          'notification_title',
          'subject',
          'heading',
          'alert_title',
        ]) ??
        '';
  }

  String body = '';
  if (n?.body != null && n!.body!.trim().isNotEmpty) {
    body = n.body!.trim();
  } else {
    body = _stringFromData(data, [
          'body',
          'message',
          'text',
          'alert',
          'content',
          'description',
          'gcm.notification.body',
        ]) ??
        _lookupCi(merged, [
          'body',
          'message',
          'text',
          'description',
          'content',
          'detail',
          'msg',
          'alert',
        ]) ??
        '';
  }

  // Same shape as API notification-list: type = "New Bid Received", message = HTML.
  final flatOrMergedType =
      _lookupCi(merged, ['type']) ?? data['type']?.toString().trim();
  if (flatOrMergedType != null &&
      flatOrMergedType.isNotEmpty &&
      _looksLikeUserFacingTitle(flatOrMergedType)) {
    if (title.isEmpty || title == 'FiksOpp') {
      title = flatOrMergedType;
    }
  }

  if (title.isEmpty && body.isEmpty && merged.isNotEmpty) {
    final hint = _lookupCi(merged, [
      'notification-type',
      'notification_type',
      'activity',
      'type',
    ]);
    if (hint != null) {
      title = 'FiksOpp';
      body = hint.replaceAll('_', ' ');
    }
  }

  if (body.isEmpty) {
    final flatType = data['type']?.toString().trim();
    if (flatType != null && flatType.isNotEmpty) {
      body = flatType;
    }
  }
  if (title.isEmpty && body.isNotEmpty) {
    title = 'FiksOpp';
  }

  // Last resort: machine notification-type + job/booking hint (still better than silence).
  if (title.isEmpty && body.isEmpty && merged.isNotEmpty) {
    final nt = _lookupCi(merged, ['notification-type', 'notification_type']);
    final jid = merged['job_id'] ?? merged['job_request_id'] ?? merged['id'];
    if (nt != null) {
      title = 'FiksOpp';
      body = _stripHtmlToPlain(
          '${nt.replaceAll('_', ' ')}${jid != null ? ' · #$jid' : ''}');
    }
  }

  body = _stripHtmlToPlain(body);

  return FcmDisplayText(title, body);
}

/// Debug / staging: log full FCM shape so backend can compare chat vs bid payloads.
/// Filter Xcode / Dart console: `FCM|inbound`
void logFcmInboundDiagnostics(RemoteMessage message, {required String phase}) {
  if (kReleaseMode) return;
  final n = message.notification;
  final data = message.data;
  final merged = fcmMergedDataMap(data);
  final display = fcmResolveDisplayText(message);
  final keys = data.keys.toList()..sort();
  debugPrint('[FCM|inbound] phase=$phase '
      'collapseKey=${message.collapseKey} messageId=${message.messageId}');
  debugPrint('[FCM|inbound] notificationBlockPresent=${n != null} '
      'title=${n?.title} bodyLen=${n?.body?.length ?? 0}');
  debugPrint('[FCM|inbound] dataKeyCount=${keys.length} keys=$keys');
  if (merged.isNotEmpty) {
    final ak = merged.keys.toList()..sort();
    debugPrint('[FCM|inbound] mergedJson keyCount=${ak.length} keys=$ak');
    final nt = merged['notification-type'] ?? merged['notification_type'];
    if (nt != null)
      debugPrint('[FCM|inbound] additional notification-type=$nt');
  }
  debugPrint('[FCM|inbound] resolved titleLen=${display.title.length} '
      'bodyLen=${display.body.length} hasContent=${display.hasContent}');
  if (!display.hasContent) {
    debugPrint(
        '[FCM|inbound] NO_BANNER_TEXT: add FCM `notification` {title,body} '
        'or put text in data.message / data.body / additional_data JSON.');
  }
}
