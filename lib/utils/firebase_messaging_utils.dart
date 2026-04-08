import 'dart:convert';
import 'dart:io';

import 'package:fiksOpp/utils/common.dart';
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

bool _foregroundNotificationListenersRegistered = false;
bool _fcmLocalNotificationsReady = false;

final FlutterLocalNotificationsPlugin _fcmLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initializes local notifications once, before FCM, so iOS assigns
/// [UNUserNotificationCenter] delegate correctly and foreground banners work.
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
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
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
    // iOS: show foreground UI via flutter_local_notifications (banner/list).
    // FCM's own foreground presentation fights for the same delegate and often
    // produces no visible banner; disable FCM's duplicate on iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: !Platform.isIOS,
      badge: true,
      sound: !Platform.isIOS,
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
      Map<String, dynamic> additional = const {};
      final additionalRaw = message.data['additional_data'];
      if (additionalRaw is String && additionalRaw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(additionalRaw);
          if (decoded is Map<String, dynamic>) additional = decoded;
        } catch (_) {}
      }

      final n = message.notification;
      final title = n?.title.validate().isNotEmpty == true
          ? n!.title.validate()
          : (message.data['title']?.toString() ??
              message.data['gcm.notification.title']?.toString() ??
              additional['type']?.toString() ??
              '');
      final bodyRaw = n?.body.validate().isNotEmpty == true
          ? n!.body.validate()
          : (message.data['body']?.toString() ??
              message.data['message']?.toString() ??
              message.data['gcm.notification.body']?.toString() ??
              additional['message']?.toString() ??
              '');
      if (title.isNotEmpty || bodyRaw.isNotEmpty) {
        showNotification(
          currentTimeStamp(),
          title.isNotEmpty ? title : 'FiksOpp',
          bodyRaw.isNotEmpty ? parseHtmlString(bodyRaw) : ' ',
          message,
        );
      }
    }, onError: (e) {
      log("setAutoInitEnabled error $e");
    });

    // replacement for onResume: When the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationClick(message);
    }, onError: (e) {
      log("onMessageOpenedApp Error $e");
    });

    // workaround for onLaunch: When the app is completely closed (not in the background) and opened directly from the push notification
    FirebaseMessaging.instance.getInitialMessage().then(
        (RemoteMessage? message) {
      if (message != null) {
        handleNotificationClick(message);
      }
    }, onError: (e) {
      log("getInitialMessage error : $e");
    });
  }).onError((error, stackTrace) {
    log("onGetInitialMessage error: $error");
  });
}

void handleNotificationClick(RemoteMessage message) {
  if (message.data['url'] != null && message.data['url'] is String) {
    commonLaunchUrl(message.data['url'],
        launchMode: LaunchMode.externalApplication);
  }
  if (message.data.containsKey('is_chat')) {
    LiveStream().emit(LIVESTREAM_FIREBASE, 3);
  } else if (message.data.containsKey('additional_data')) {
    Map<String, dynamic> additionalData =
        jsonDecode(message.data["additional_data"]) ?? {};
    int? id;
    if (additionalData.containsKey('id') && additionalData['id'] != null) {
      id = additionalData['id'];
      if (additionalData.containsKey('notification-type') &&
          additionalData['notification-type'] == 'provider_send_bid') {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => MyPostDetailScreen(
              postRequestId: id.validate(),
              callback: () {},
            ),
          ),
        );
      } else if (additionalData.containsKey('check_booking_type') &&
          additionalData['check_booking_type'] == 'booking') {
        navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) =>
                BookingDetailScreen(bookingId: additionalData['id'].toInt())));
      } else if (additionalData.containsKey('type') &&
          additionalData['type'] == 'update_wallet') {
        navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => UserWalletBalanceScreen()));
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
  // endregion

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
