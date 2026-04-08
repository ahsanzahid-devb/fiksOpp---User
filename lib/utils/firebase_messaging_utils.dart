import 'dart:convert';
import 'dart:io';
import 'package:fiksOpp/utils/common.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../screens/booking/booking_detail_screen.dart';
import '../screens/jobRequest/my_post_detail_screen.dart';
import '../screens/service/service_detail_screen.dart';
import '../screens/wallet/user_wallet_balance_screen.dart';
import 'constant.dart';
import 'fcm_payload_utils.dart';

bool _foregroundNotificationListenersRegistered = false;
bool _fcmLocalNotificationsReady = false;

final FlutterLocalNotificationsPlugin _fcmLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> ensureFcmLocalNotificationsPluginReady() async {
  if (_fcmLocalNotificationsReady) return;

  const androidChannel = AndroidNotificationChannel(
    'notification',
    'Notification',
    importance: Importance.high,
    enableLights: true,
    playSound: true,
    showBadge: true,
  );
  await _fcmLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  const androidInit =
      AndroidInitializationSettings('@drawable/ic_stat_ic_notification');
  const darwinInit = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
    defaultPresentAlert: true,
    defaultPresentSound: true,
    defaultPresentBadge: true,
    defaultPresentBanner: true,
    defaultPresentList: true,
  );

  await _fcmLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final p = response.payload;
      if (p == null || p.isEmpty) return;
      try {
        final decoded = jsonDecode(p);
        if (decoded is Map<String, dynamic>) {
          handleNotificationClick(RemoteMessage(data: decoded));
        } else if (decoded is Map) {
          handleNotificationClick(
              RemoteMessage(data: Map<String, dynamic>.from(decoded)));
        }
      } catch (e) {
        log('notification tap payload: $e');
      }
    },
  );

  if (Platform.isIOS) {
    await _fcmLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  _fcmLocalNotificationsReady = true;
}

Future<void> initFirebaseMessaging() async {
  await ensureFcmLocalNotificationsPluginReady();

  final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, provisional: false, sound: true);

  // Register streams even when alerts are denied or only provisional; otherwise
  // FirebaseMessaging.onMessage never runs and foreground/data handling breaks.
  await registerNotificationListeners().catchError((e) {
    log('Notification Listener REGISTRATION ERROR : ${e}');
  });

  final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
  if (ok) {
    // iOS: must allow FCM/APNs foreground presentation when the server sends a
    // `notification` { title, body }. Relying only on flutter_local_notifications
    // often shows no banner for topic/data-heavy FCM. We skip duplicate local
    // notifications in onMessage when `message.notification` is already set.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    )
        .catchError((e) {
      log('setForegroundNotificationPresentationOptions ERROR: ${e}');
    });
  }
}

Future<bool> subscribeToFirebaseTopic() async {
  bool result = appStore.isSubscribedForPushNotification;
  if (appStore.isLoggedIn) {
    await initFirebaseMessaging();

    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        await 3.seconds.delay;
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }

      log('Apn Token=========${apnsToken}');
    }

    await FirebaseMessaging.instance
        .subscribeToTopic('user_${appStore.userId}')
        .then((value) {
      result = true;
      log("topic-----subscribed----> user_${appStore.userId}");
    });
    await FirebaseMessaging.instance
        .subscribeToTopic(USER_APP_TAG)
        .then((value) {
      result = true;
      log("topic-----subscribed----> $USER_APP_TAG");
    });
  }

  await appStore.setPushNotificationSubscriptionStatus(result);
  return result;
}

Future<bool> unsubscribeFirebaseTopic(int userId) async {
  bool result = appStore.isSubscribedForPushNotification;
  await FirebaseMessaging.instance
      .unsubscribeFromTopic('user_$userId')
      .then((_) {
    result = false;
    log("topic-----unsubscribed----> user_$userId");
  });
  await FirebaseMessaging.instance.unsubscribeFromTopic(USER_APP_TAG).then((_) {
    result = false;
    log("topic-----unsubscribed----> $USER_APP_TAG");
  });

  await appStore.setPushNotificationSubscriptionStatus(result);
  return result;
}

Future<void> registerNotificationListeners() async {
  if (_foregroundNotificationListenersRegistered) return;
  _foregroundNotificationListenersRegistered = true;

  FirebaseMessaging.instance.setAutoInitEnabled(true).then((value) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logFcmInboundDiagnostics(message, phase: 'foreground_onMessage');
      final display = fcmResolveDisplayText(message);
      final n = message.notification;

      final nativeTitle = n?.title?.trim() ?? '';
      final nativeBody = n?.body?.trim() ?? '';
      final nativeBannerComplete =
          nativeTitle.isNotEmpty && nativeBody.isNotEmpty;
      final showLocalBanner =
          display.hasContent && !(Platform.isIOS && nativeBannerComplete);
      if (showLocalBanner) {
        showNotification(
          currentTimeStamp(),
          display.title.isNotEmpty ? display.title : 'FiksOpp',
          display.body.isNotEmpty ? parseHtmlString(display.body) : ' ',
          message,
        );
      } else if (kDebugMode) {
        if (Platform.isIOS && nativeBannerComplete) {
          debugPrint(
              '[FCM|inbound] foreground iOS: using system banner (full notification block)');
        } else if (!display.hasContent) {
          debugPrint(
              '[FCM|inbound] foreground: no banner (add FCM notification{} or resolvable data)');
        }
      }
    }, onError: (e) {
      log("setAutoInitEnabled error $e");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logFcmInboundDiagnostics(message, phase: 'opened_from_tray');
      handleNotificationClick(message);
    }, onError: (e) {
      log("onMessageOpenedApp Error $e");
    });

    FirebaseMessaging.instance.getInitialMessage().then(
        (RemoteMessage? message) {
      if (message != null) {
        logFcmInboundDiagnostics(message, phase: 'initial_message_cold_start');
        handleNotificationClick(message);
      }
    }, onError: (e) {
      log("getInitialMessage error : $e");
    });
  }).onError((error, stackTrace) {
    log("onGetInitialMessage error: $error");
  });
}

int? _postJobIdFromFlatBidData(Map<String, dynamic> d) {
  final nType =
      d['notification-type']?.toString() ?? d['notification_type']?.toString();
  if (nType != 'provider_send_bid') return null;
  final raw = d['job_id'] ?? d['job_request_id'] ?? d['post_request_id'];
  if (raw == null) return null;
  return int.tryParse(raw.toString());
}

void handleNotificationClick(RemoteMessage message) {
  if (message.data['url'] != null && message.data['url'] is String) {
    commonLaunchUrl(message.data['url'],
        launchMode: LaunchMode.externalApplication);
  }
  if (message.data.containsKey('is_chat')) {
    LiveStream().emit(LIVESTREAM_FIREBASE, 3);
  } else {
    final flatBidPostId = _postJobIdFromFlatBidData(message.data);
    if (flatBidPostId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MyPostDetailScreen(
            postRequestId: flatBidPostId,
            callback: () {},
          ),
        ),
      );
    } else {
      final Map<String, dynamic> additionalData =
          fcmMergedDataMap(message.data);
      if (additionalData.isEmpty) return;

      int? postJobIdForBid;
      if (additionalData['notification-type']?.toString() ==
              'provider_send_bid' ||
          additionalData['notification_type']?.toString() ==
              'provider_send_bid') {
        postJobIdForBid = int.tryParse((additionalData['job_id'] ??
                additionalData['job_request_id'] ??
                additionalData['post_request_id'] ??
                additionalData['id'])
            .toString());
      }

      if (postJobIdForBid != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MyPostDetailScreen(
              postRequestId: postJobIdForBid.validate(),
              callback: () {},
            ),
          ),
        );
      } else if (additionalData.containsKey('id') &&
          additionalData['id'] != null) {
        final id = additionalData['id'];
        if (additionalData.containsKey('check_booking_type') &&
            additionalData['check_booking_type'] == 'booking') {
          navigatorKey.currentState!.push(MaterialPageRoute(
              builder: (context) =>
                  BookingDetailScreen(bookingId: id.toInt())));
        } else if (additionalData.containsKey('type') &&
            additionalData['type'] == 'update_wallet') {
          navigatorKey.currentState!.push(MaterialPageRoute(
              builder: (context) => UserWalletBalanceScreen()));
        }
      }
      if (additionalData.containsKey('service_id') &&
          additionalData["service_id"] != null) {
        navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
                serviceId: additionalData["service_id"].toInt())));
      }
    }
  }
}

void showNotification(
    int id, String title, String message, RemoteMessage remoteMessage) async {
  log('Notification : ${remoteMessage.notification?.toMap()} | data: ${remoteMessage.data}');
  log('Message Data : ${remoteMessage.data}');
  log("User Message Image Url : ${remoteMessage.data["image_url"]} ");
  await ensureFcmLocalNotificationsPluginReady();

  // region image logic
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  BigPictureStyleInformation? bigPictureStyleInformation =
      remoteMessage.data.containsKey("image_url")
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(await _downloadAndSaveFile(
                  remoteMessage.data["image_url"], 'bigPicture')),
              largeIcon: FilePathAndroidBitmap(await _downloadAndSaveFile(
                  remoteMessage.data["image_url"], 'largeIcon')),
            )
          : null;

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'notification',
    'Notification',
    importance: Importance.high,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    playSound: true,
    priority: Priority.high,
    icon: '@drawable/ic_stat_ic_notification',
    largeIcon: remoteMessage.data.containsKey("image_url")
        ? FilePathAndroidBitmap(await _downloadAndSaveFile(
            remoteMessage.data["image_url"], 'largeIcon'))
        : null,
    styleInformation: remoteMessage.data.containsKey("image_url")
        ? bigPictureStyleInformation
        : null,
  );

  const darwinPlatformChannelSpecifics = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    presentList: true,
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: darwinPlatformChannelSpecifics,
    macOS: darwinPlatformChannelSpecifics,
  );

  await _fcmLocalNotificationsPlugin.show(
    id,
    title,
    parseHtmlString(message),
    platformChannelSpecifics,
    payload: jsonEncode(remoteMessage.data),
  );
}
