import 'dart:io';

import 'package:fiksOpp/component/app_common_dialog.dart';
import 'package:fiksOpp/component/html_widget.dart';
import 'package:fiksOpp/component/location_service_dialog.dart';
import 'package:fiksOpp/component/new_update_dialog.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/network/rest_apis.dart';
import 'package:fiksOpp/screens/auth/sign_in_screen.dart';
import 'package:fiksOpp/services/location_service.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/images.dart';
import 'package:fiksOpp/utils/permissions.dart';
import 'package:fiksOpp/utils/string_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../component/cached_image_widget.dart';
import 'app_configuration.dart';
import 'configs.dart';
import 'constant.dart';

Future<bool> get isIqonicProduct async =>
    await getPackageName() == appPackageName;

/// Stripe/Razorpay/PayPal (and similar) must use the same ISO currency as [currencySymbol] from admin.
/// Do **not** use [isIqonicProduct] here: on Android, `buzz.inoor.fiksopp` matches [appPackageName] and
/// the old branch forced INR while the UI still showed e.g. `kr` → Stripe `amount_too_small` / wrong FX.
String paymentGatewayCurrencyCode() {
  final c = appConfigurationStore.currencyCode.trim().toLowerCase();
  if (c.isEmpty) return DEFAULT_PAYMENT_CURRENCY_CODE;
  return c;
}

bool get isUserTypeHandyman => appStore.userType == USER_TYPE_HANDYMAN;

bool get isUserTypeProvider => appStore.userType == USER_TYPE_PROVIDER;

bool get isUserTypeUser => appStore.userType == USER_TYPE_USER;

bool get isLoginTypeUser => appStore.loginType == LOGIN_TYPE_USER;

bool get isLoginTypeGoogle => appStore.loginType == LOGIN_TYPE_GOOGLE;

bool get isLoginTypeApple => appStore.loginType == LOGIN_TYPE_APPLE;

bool get isLoginTypeOTP => appStore.loginType == LOGIN_TYPE_OTP;

ThemeMode get appThemeMode =>
    appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light;

bool get isRTL => RTL_LanguageS.contains(appStore.selectedLanguageCode);

Future<void> commonLaunchUrl(String address,
    {LaunchMode launchMode = LaunchMode.inAppWebView}) async {
  await launchUrl(Uri.parse(address), mode: launchMode).catchError((e) {
    toast('${language.invalidURL}: $address');

    throw e;
  });
}

void viewFiles(String url) {
  if (url.isNotEmpty) {
    commonLaunchUrl(url, launchMode: LaunchMode.externalApplication);
  }
}

/// Opens the system dialer. Uses `tel:+47…` (not `tel://…`, which breaks `+` on iOS).
/// On Simulator, [launchUrl] usually returns false — number is copied and a hint is shown.
Future<void> launchCall(String? raw) async {
  if (raw == null || raw.trim().isEmpty) return;

  var s = raw.trim();
  if (s.toLowerCase().startsWith('tel:')) {
    s = s.substring(4).trim();
  }
  s = s.replaceAll(RegExp(r'[\s\-]'), '');
  if (s.isEmpty) return;

  final uri = Uri.parse('tel:$s');

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: s));
      toast(
        'Copied $s — Simulator/emulator cannot open Phone. Test on a real device or paste the number.',
      );
    }
  } catch (e) {
    try {
      await Clipboard.setData(ClipboardData(text: s));
    } catch (_) {}
    toast('Could not open dialer. Copied: $s');
  }
}

/// Support line for the dialer: admin [helpline_number] when set, else [DEFAULT_HELPLINE_NUMBER].
String effectiveSupportHelpline() {
  final t = appConfigurationStore.helplineNumber.trim();
  if (t.isNotEmpty) return t;
  return DEFAULT_HELPLINE_NUMBER;
}

/// Apple public store URLs must include a numeric app id. Values like
/// `https://apps.apple.com` from the admin API open the App Store home, not this app.
String? _appleAppStoreListingId(String raw) {
  final m1 = RegExp(r'id(\d+)').firstMatch(raw);
  if (m1 != null) return m1.group(1);
  final m2 = RegExp(r'[?&]id=(\d+)').firstMatch(raw);
  return m2?.group(1);
}

bool _isValidAppStoreListingUrl(String raw) {
  final u = Uri.tryParse(raw.trim());
  if (u == null || u.host.isEmpty) return false;
  final host = u.host.toLowerCase();
  // Admin console links are not valid for "open in App Store" from the device.
  if (host.contains('appstoreconnect.apple.com')) return false;
  if (isIOS) {
    if (!host.contains('apps.apple.com') &&
        !host.contains('itunes.apple.com')) {
      return false;
    }
    return _appleAppStoreListingId(raw) != null;
  }
  if (host != 'play.google.com' && !host.endsWith('.play.google.com')) {
    return false;
  }
  return u.path.contains('/details') &&
      (u.queryParameters['id']?.isNotEmpty ?? false);
}

/// iOS: `itms-apps://itunes.apple.com/app/id…` is the most reliable deep link into the App Store app.
/// `itms-apps://apps.apple.com/app/…` can be handed to Safari on some OS versions and shows "invalid address".
String iosAppStoreNativeOpenUrl(String webUrl) {
  final id = _appleAppStoreListingId(webUrl);
  if (id != null) {
    return 'itms-apps://itunes.apple.com/app/id$id';
  }
  return webUrl;
}

/// Short https form; on device iOS usually resolves this to the App Store app (not a Safari page).
String _iosAppStoreHttpsAppLink(String id) =>
    'https://apps.apple.com/app/id$id';

Future<bool> _launchExternalUri(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e, st) {
    log('launchUrl failed: $e\n$st');
    return false;
  }
}

/// Opens Play Store / App Store listing for the customer app (from app configuration or package fallback).
Future<void> openCustomerAppStoreListing() async {
  try {
    if (isIOS) {
      // Always open this app's listing using bundled id + URL. Persisted `APPSTORE_URL` from
      // the API is often `https://apps.apple.com` and opens the Store home instead of FiksOpp.
      final id = CUSTOMER_APP_APP_STORE_NUMERIC_ID.trim();
      if (id.isEmpty) {
        toast(language.invalidURL);
        return;
      }

      final storeUris = <Uri>[
        Uri.parse('itms-apps://itunes.apple.com/app/id$id'),
        Uri.parse('itms-apps://apps.apple.com/app/id$id'),
        Uri.parse('itms://itunes.apple.com/app/id$id'),
      ];
      for (final u in storeUris) {
        if (await _launchExternalUri(u)) return;
      }
      final httpsFallback = CUSTOMER_APP_APP_STORE_LISTING.isNotEmpty
          ? CUSTOMER_APP_APP_STORE_LISTING
          : _iosAppStoreHttpsAppLink(id);
      if (await _launchExternalUri(Uri.parse(httpsFallback))) return;
      toast(language.invalidURL);
      return;
    }

    final u = getStringAsync(CUSTOMER_PLAY_STORE_URL).trim();
    if (u.isNotEmpty && _isValidAppStoreListingUrl(u)) {
      if (await _launchExternalUri(Uri.parse(u))) return;
    }
    final pkg = await getPackageName();
    final playListing = CUSTOMER_APP_PLAY_STORE_LISTING.isNotEmpty
        ? CUSTOMER_APP_PLAY_STORE_LISTING
        : 'https://play.google.com/store/apps/details?id=$pkg';
    if (await _launchExternalUri(Uri.parse(playListing))) return;
    toast(language.invalidURL);
  } catch (e) {
    toast(e.toString());
  }
}

void launchMap(String? url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl(GOOGLE_MAP_PREFIX + Uri.encodeFull(url!),
        launchMode: LaunchMode.externalApplication);
  }
}

void launchMail(String url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl('$MAIL_TO$url', launchMode: LaunchMode.externalApplication);
  }
}

void checkIfLink(BuildContext context, String value, {String? title}) {
  if (value.validate().isEmpty) return;

  String temp = parseHtmlString(value.validate());
  if (temp.startsWith("https") || temp.startsWith("http")) {
    launchUrlCustomTab(temp.validate());
  } else if (temp.validateEmail()) {
    launchMail(temp);
  } else if (temp.validatePhone() || temp.startsWith('+')) {
    launchCall(temp);
  } else {
    HtmlWidget(postContent: value, title: title).launch(context);
  }
}

void launchUrlCustomTab(String? url) {
  if (url.validate().isNotEmpty) {
    custom_tabs.launchUrl(
      Uri.parse(url!),
      customTabsOptions: custom_tabs.CustomTabsOptions(
        showTitle: true,
        colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
            toolbarColor: primaryColor),
      ),
      safariVCOptions: custom_tabs.SafariViewControllerOptions(
        preferredBarTintColor: primaryColor,
        preferredControlTintColor: Colors.white,
        barCollapsingEnabled: true,
        entersReaderIfAvailable: true,
        dismissButtonStyle:
            custom_tabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }
}

List<LanguageDataModel> languageList() {
  return [
    // Norwegian as primary language
    LanguageDataModel(
        id: 1,
        name: 'Norsk',
        languageCode: 'no',
        fullLanguageCode: 'nb-NO',
        flag: 'assets/flag/ic_us.png'),
    // English as secondary option
    LanguageDataModel(
        id: 2,
        name: 'English',
        languageCode: 'en',
        fullLanguageCode: 'en-US',
        flag: 'assets/flag/ic_us.png'),
  ];
}

InputDecoration inputDecoration(
  BuildContext context, {
  Widget? prefixIcon,
  Widget? prefix,
  String? labelText,
  String? hintText,
  double? borderRadius,
  bool? counter,
  String? counterText,
  Color? fillColor,
}) {
  return InputDecoration(
    contentPadding: EdgeInsets.only(left: 12, bottom: 10, top: 10, right: 10),
    labelText: labelText,
    labelStyle: secondaryTextStyle(),
    hintText: hintText,
    hintStyle: secondaryTextStyle(),
    alignLabelWithHint: true,
    counterText: counter == false ? "" : counterText,
    prefixIcon: prefixIcon,
    prefix: prefix,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.red, width: 0.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.red, width: 1.0),
    ),
    errorMaxLines: 2,
    border: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    ),
    errorStyle: primaryTextStyle(color: Colors.red, size: 12),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: BorderSide(color: primaryColor, width: 0.0),
    ),
    filled: true,
    fillColor: fillColor ?? context.cardColor,
  );
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

String formatDate(String? dateTime,
    {bool isFromMicrosecondsSinceEpoch = false,
    bool isLanguageNeeded = true,
    bool isTime = false,
    bool showDateWithTime = false}) {
  final languageCode = isLanguageNeeded ? appStore.selectedLanguageCode : null;
  final parsedDateTime = isFromMicrosecondsSinceEpoch
      ? DateTime.fromMicrosecondsSinceEpoch(dateTime.validate().toInt() * 1000)
      : DateTime.parse(dateTime.validate());
  if (isTime) {
    return DateFormat('${getStringAsync(TIME_FORMAT)}', languageCode)
        .format(parsedDateTime);
  } else {
    if (getStringAsync(DATE_FORMAT).validate().contains('dS')) {
      int day = parsedDateTime.day;
      if (DateFormat('${getStringAsync(DATE_FORMAT)}', languageCode)
          .format(parsedDateTime)
          .contains('$day')) {
        return DateFormat(
                '${getStringAsync(DATE_FORMAT).replaceAll('S', '')}${showDateWithTime ? ' ${getStringAsync(TIME_FORMAT)}' : ''}',
                languageCode)
            .format(parsedDateTime)
            .replaceFirst('$day', '${addOrdinalSuffix(day)}');
      }
    }
    return DateFormat(
            '${getStringAsync(DATE_FORMAT)}${showDateWithTime ? ' ${getStringAsync(TIME_FORMAT)}' : ''}',
            languageCode)
        .format(parsedDateTime);
  }
}

String formatBookingDate(String? dateTime,
    {String format = DATE_FORMAT_1,
    bool isFromMicrosecondsSinceEpoch = false,
    bool isLanguageNeeded = true,
    bool isTime = false,
    bool showDateWithTime = false}) {
  final languageCode = isLanguageNeeded ? appStore.selectedLanguageCode : null;
  final parsedDateTime = isFromMicrosecondsSinceEpoch
      ? DateTime.fromMicrosecondsSinceEpoch(dateTime.validate().toInt() * 1000)
      : DateTime.parse(dateTime.validate());

  return DateFormat(format, languageCode).format(parsedDateTime);
}

String getSlotWithDate({required String date, required String slotTime}) {
  DateTime originalDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
  DateTime newTime = DateFormat('HH:mm:ss').parse(slotTime);
  DateTime newDateTime = DateTime(originalDateTime.year, originalDateTime.month,
      originalDateTime.day, newTime.hour, newTime.minute, newTime.second);
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime);
}

String getConfirmBookingDateFormat({required String date}) {
  DateTime originalDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
  return DateFormat("d MMMM, yyyy, 'at' h:mm a").format(originalDateTime);
}

String getDateFormat(String phpFormat) {
  final formatMapping = {
    'Y': 'yyyy',
    'm': 'MM',
    'd': 'dd',
    'j': 'd',
    'S': 'S',
    'M': 'MMM',
    'F': 'MMMM',
    'l': 'EEEE',
    'D': 'EEE',
    'H': 'HH',
    'i': 'mm',
    's': 'ss',
    'A': 'a',
    'T': 'z',
    'v': 'S',
    'U': 'y-MM-ddTHH:mm:ssZ',
    'u': 'y-MM-ddTHH:mm:ss.SSSZ',
    'G': 'H',
    'B': 'EEE, d MMM y HH:mm:ss Z',
  };

  String dartFormat = phpFormat.replaceAllMapped(
    RegExp('[YmjdSFMlDHisaTvGuB]'),
    (match) => formatMapping[match.group(0)] ?? match.group(0).validate(),
  );

  dartFormat = dartFormat.replaceAllMapped(
    RegExp(r"\\(.)"),
    (match) => match.group(1) ?? '',
  );

  return dartFormat;
}

String addOrdinalSuffix(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String getDisplayTimeFormat(String phpFormat) {
  switch (phpFormat) {
    case 'H:i':
      return 'HH:mm';
    case 'H:i:s':
      return 'HH:mm:ss';
    case 'g:i A':
      return 'h:mm a';
    case 'H:i:s T':
      return 'HH:mm:ss z';
    case 'H:i:s.v':
      return 'HH:mm:ss.S';
    case 'U':
      return 'HH:mm:ssZ';
    case 'u':
      return 'HH:mm:ss.SSSZ';
    case 'G.i':
      return 'H.mm';
    case '@BMT':
      return 'HH:mm:ss Z';
    default:
      return DISPLAY_TIME_FORMAT; // Return the same format if not found in the mapping
  }
}

bool containsTime(String dateString) {
  RegExp timeRegex = RegExp(r'\b\d{1,2}:\d{1,2}(:\d{1,2})?\b');

  return timeRegex.hasMatch(dateString);
}

Future<bool> addToWishList({required int serviceId}) async {
  Map req = {"id": "", "service_id": serviceId, "user_id": appStore.userId};
  return await addWishList(req).then((res) {
    toast(language.serviceAddedToFavourite);
    return true;
  }).catchError((error) {
    toast(error.toString());
    return false;
  });
}

Future<bool> removeToWishList({required int serviceId}) async {
  Map req = {"user_id": appStore.userId, 'service_id': serviceId};

  return await removeWishList(req).then((res) {
    toast(language.serviceRemovedFromFavourite);
    return true;
  }).catchError((error) {
    toast(error.toString());
    return false;
  });
}

void locationWiseService(BuildContext context, VoidCallback onTap) async {
  Permissions.requestLocationWhenInUseForServices().then((value) async {
    if (!value) {
      if (await Permissions.isLocationPermanentlyDenied()) {
        toast(language.lblLocationPermissionDeniedPermanently);
      }
      return;
    }

    bool? res = await showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      builder: (p0) {
        return AppCommonDialog(
          title: language.lblAlert,
          child: LocationServiceDialog(),
        );
      },
    );

    if (res ?? false) {
      appStore.setLoading(true);

      await getUserLocation().then((value) async {
        // Location was fetched successfully; keep location mode enabled.
        await appStore.setCurrentLocation(true);
        appStore.setLoading(false);
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });

      onTap.call();
    }
  }).catchError((e) {
    toast(e.toString(), print: true);
  });
}

void location(BuildContext context, {VoidCallback? onRefresh}) async {
  // Home is rebuilt each time the user returns from e.g. "All Services". Re-running
  // Geolocator + permission checks every time can re-trigger iOS system UI. If we
  // already have coords and When-In-Use access, only refresh dashboard data.
  try {
    if (appStore.isCurrentLocation &&
        getDoubleAsync(LATITUDE) != 0 &&
        getDoubleAsync(LONGITUDE) != 0 &&
        await Geolocator.isLocationServiceEnabled() &&
        await Permissions.hasLocationWhenInUseGranted()) {
      onRefresh?.call();
      return;
    }
  } catch (_) {
    // Continue with full location flow below.
  }

  Permissions.requestLocationWhenInUseForServices()
      .then((permissionGranted) async {
    if (permissionGranted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await showInDialog(
          context,
          contentPadding: EdgeInsets.zero,
          builder: (p0) {
            return AppCommonDialog(
              title: language.lblAlert,
              child: LocationServiceDialog(),
            );
          },
        );

        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          toast(language.lblEnableLocation);
          if (onRefresh != null) onRefresh.call();
          return;
        }
      }

      appStore.setLoading(true);

      await getUserLocation().then((_) async {
        // Location was fetched successfully; keep location mode enabled.
        await appStore.setCurrentLocation(true);
        appStore.setLoading(false);
        if (onRefresh != null) onRefresh.call();
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
        if (onRefresh != null) onRefresh.call(); // <- Still refresh!
      });
    } else {
      // Permission Denied - Still load dashboard with fallback data
      if (onRefresh != null) onRefresh.call();
    }
  }).catchError((e) {
    appStore.setLoading(false);
    toast(e.toString(), print: true);
    if (onRefresh != null)
      onRefresh.call(); // <- Handle error by calling init()
  });
}

Future<List<File>> pickFiles({
  FileType type = FileType.any,
  List<String> allowedExtensions = const [],
  int maxFileSizeMB = 5,
  bool allowMultiple = false,
}) async {
  List<File> _filePath = [];
  try {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: allowMultiple,
      withData: Platform.isAndroid ? false : true,
      allowedExtensions: allowedExtensions,
      onFileLoading: (FilePickerStatus status) => print(status),
    );
    if (filePickerResult != null) {
      if (Platform.isAndroid) {
        // For Android, check file size and use the PlatformFile directly
        for (PlatformFile file in filePickerResult.files) {
          if (file.size <= maxFileSizeMB * 1024 * 1024) {
            _filePath.add(File(file.path!));
          } else {
            // File size exceeds the limit
            toast('${language.fileSizeShouldBeLessThan} $maxFileSizeMB MB');
          }
        }
      } else {
        Directory cacheDir = await getTemporaryDirectory();
        for (PlatformFile file in filePickerResult.files) {
          if (file.bytes != null && file.size <= maxFileSizeMB * 1024 * 1024) {
            String filePath = '${cacheDir.path}/${file.name}';
            File cacheFile = File(filePath);
            await cacheFile.writeAsBytes(file.bytes!.toList());
            _filePath.add(cacheFile);
          } else {
            // File size exceeds the limit
            toast('${language.fileSizeShouldBeLessThan} $maxFileSizeMB MB');
          }
        }
      }
    }
  } on PlatformException catch (e) {
    print('Unsupported operation' + e.toString());
  } catch (e) {
    print(e.toString());
  }
  return _filePath;
}

// Logic For Calculate Time
String calculateTimer(int secTime) {
  int hour = 0, minute = 0, seconds = 0;

  hour = secTime ~/ 3600;

  minute = ((secTime - hour * 3600)) ~/ 60;

  seconds = secTime - (hour * 3600) - (minute * 60);

  String hourLeft =
      hour.toString().length < 2 ? "0" + hour.toString() : hour.toString();

  String minuteLeft = minute.toString().length < 2
      ? "0" + minute.toString()
      : minute.toString();

  String minutes = minuteLeft == '00' ? '01' : minuteLeft;

  String result = "$hourLeft:$minutes";

  log(seconds);

  return result;
}

String convertToHourMinute(String timeStr) {
  if (timeStr.isEmpty) {
    return ''; // Handle empty time string
  }

  // Normalize time string to always have two digits for hours
  List<String> parts = timeStr.split(':');
  int hours = int.parse(parts[0]) % 24; // Ensure hours are within 24 hours
  int minutes = int.parse(parts[1]);

  // Construct the resulting string
  String result = '';
  if (hours > 0) {
    result += '${hours}${language.lblHr}';
  }
  if (minutes > 0) {
    result = (result.validate().isNotEmpty)
        ? '$result $minutes ${language.min}'
        : '$minutes ${language.min}';
  }
  return result;
}

String getPaymentStatusFilterText(String? status) {
  if (status!.isEmpty) {
    return language.lblPending;
  } else if (status == SERVICE_PAYMENT_STATUS_PAID ||
      status == PENDING_BY_ADMIN) {
    return language.paid;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
    return language.advancePaid;
  } else if (status == SERVICE_PAYMENT_STATUS_PENDING) {
    return language.lblPending;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_REFUND) {
    return language.advancedRefund;
  } else {
    return "";
  }
}

String getPaymentStatusText(String? status, String? method) {
  if (status!.isEmpty) {
    return language.lblPending;
  } else if (status == SERVICE_PAYMENT_STATUS_PAID ||
      status == PENDING_BY_ADMIN) {
    return language.paid;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
    return language.advancePaid;
  } else if ((status == SERVICE_PAYMENT_STATUS_PENDING ||
          status == 'pending_approval') &&
      method == PAYMENT_METHOD_COD) {
    return language
        .pendingApproval; //TODO: check this condition 'pending_approval' status not coming from backend
  } else if (status == SERVICE_PAYMENT_STATUS_PENDING) {
    return language.lblPending;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_REFUND) {
    return language.cancelled;
  } else {
    return "";
  }
}

String buildPaymentStatusWithMethod(String status, String method) {
  return '${getPaymentStatusText(status, method)}${(status == SERVICE_PAYMENT_STATUS_PAID || status == PENDING_BY_ADMIN) ? ' ${language.by} ${method.capitalizeFirstLetter()}' : ''}';
}

Color getRatingBarColor(int rating, {bool showRedForZeroRating = false}) {
  if (rating == 1 || rating == 2) {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  } else if (rating == 3) {
    return Color(0xFFff6200);
  } else if (rating == 4 || rating == 5) {
    return Color(0xFF73CB92);
  } else {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  }
}

void ifNotTester(VoidCallback callback) {
  if (appStore.userEmail != DEFAULT_EMAIL) {
    callback.call();
  } else {
    toast(language.lblUnAuthorized);
  }
}

void doIfLoggedIn(BuildContext context, VoidCallback callback) {
  if (appStore.isLoggedIn) {
    callback.call();
  } else {
    SignInScreen(returnExpected: true).launch(context).then((value) {
      if (value ?? false) {
        callback.call();
      }
    });
  }
}

Widget get trailing {
  return ic_arrow_right.iconImage(size: 16);
}

void showNewUpdateDialog(BuildContext context,
    {required int currentAppVersionCode}) async {
  showInDialog(
    context,
    contentPadding: EdgeInsets.zero,
    barrierDismissible:
        currentAppVersionCode >= getIntAsync(USER_APP_MINIMUM_VERSION).toInt(),
    builder: (_) {
      return WillPopScope(
        onWillPop: () {
          return Future(() =>
              currentAppVersionCode >=
              getIntAsync(USER_APP_MINIMUM_VERSION).toInt());
        },
        child: NewUpdateDialog(
            canClose: currentAppVersionCode >=
                getIntAsync(USER_APP_MINIMUM_VERSION).toInt()),
      );
    },
  );
}

Future<void> showForceUpdateDialog(BuildContext context) async {
  if (getBoolAsync(UPDATE_NOTIFY, defaultValue: true)) {
    getPackageInfo().then((value) {
      if (isAndroid &&
          getIntAsync(USER_APP_LATEST_VERSION).toInt() >
              value.versionCode.validate().toInt()) {
        showNewUpdateDialog(context,
            currentAppVersionCode: value.versionCode.validate().toInt());
      } else if (isIOS &&
          getIntAsync(USER_APP_LATEST_VERSION).toInt() >
              value.versionCode.validate().toInt()) {
        showNewUpdateDialog(context,
            currentAppVersionCode: value.versionCode.validate().toInt());
      }
    });
  }
}

bool checkTimeDifference({required DateTime inputDateTime}) {
  DateTime currentTime = DateTime.now();

  log("Booking Time Diffrence ==> ${inputDateTime.difference(currentTime).inHours}");
  if (currentTime.isBefore(inputDateTime) &&
      inputDateTime.difference(currentTime).inHours <=
          appConfigurationStore.cancellationChargeHours) {
    return true;
  }

  // Check if the current time is after the booking date and time
  if (currentTime.isAfter(inputDateTime)) {
    return false;
  }

  // Otherwise, it's more than 12 hours before the booking time
  return false;
}

String bankAccountWidget(String accountNo) {
  if (accountNo.length <= 4) {
    return accountNo;
  }
  final obscuredPart = '*' * (accountNo.length - 4);
  final visiblePart = accountNo.substring(accountNo.length - 4);
  return obscuredPart + visiblePart;
}

Widget mobileNumberInfoWidget(BuildContext context) {
  return RichTextWidget(
    list: [
      TextSpan(
          text: '${language.addYourCountryCode}', style: secondaryTextStyle()),
      TextSpan(text: ' "91-", "236-" ', style: boldTextStyle(size: 12)),
      TextSpan(
        text: ' (${language.help})',
        style: boldTextStyle(size: 12, color: primaryColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrlCustomTab("https://countrycode.org/");
          },
      ),
    ],
  );
}

class OptionListWidget extends StatelessWidget {
  final List<OptionModel> optionList;

  const OptionListWidget({super.key, required this.optionList});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        optionList.length,
        (index) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: optionList[index].onTap,
              child: Text(
                optionList[index].title,
                style: secondaryTextStyle(
                  color: primaryColor,
                  size: 12,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            8.width,
            Text("|", style: secondaryTextStyle())
                .visible(optionList.length != index + 1),
            8.width,
          ],
        ),
      ),
    );
  }
}

class OptionModel {
  final String title;
  final Function()? onTap;

  OptionModel({required this.title, required this.onTap});
}

String sumTimes(String time1, String time2) {
  // Parse the time strings into Duration objects
  Duration duration1 = _parseTimeToDuration(time1);
  Duration duration2 = _parseTimeToDuration(time2);

  // Sum the durations
  Duration totalDuration = duration1 + duration2;

  // Convert the total duration back to a formatted time string
  return _formatDurationToTime(totalDuration);
}

Duration _parseTimeToDuration(String time) {
  List<String> parts = time.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  int seconds = int.parse(parts[2]);

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

String _formatDurationToTime(Duration duration) {
  int hours = duration.inHours;
  int minutes = duration.inMinutes % 60;
  int seconds = duration.inSeconds % 60;

  return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

String _twoDigits(int n) {
  return n.toString().padLeft(2, '0');
}

void share({required String url, required BuildContext context}) {
  if (Platform.isIOS) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.instance.share(
        ShareParams(
          text: url,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      log('Failed to share: $e');
    }
  } else {
    SharePlus.instance.share(ShareParams(text: url));
  }
}

Future<List<File>> getMultipleImageSource({bool isCamera = true}) async {
  final pickedImage = await ImagePicker().pickMultiImage();
  return pickedImage.map((e) => File(e.path)).toList();
}

Future<File> getCameraImage({bool isCamera = true}) async {
  final pickedImage = await ImagePicker()
      .pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
  return File(pickedImage!.path);
}

//region Multi Language Component
class MultiLanguageWidget extends StatelessWidget {
  final Function(LanguageDataModel languageDetails) onTap;

  const MultiLanguageWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: context.scaffoldBackgroundColor),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                languageList().length,
                (index) {
                  LanguageDataModel languageData = languageList()[index];
                  return ElevatedButton(
                    onPressed: () {
                      onTap(languageData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appStore.selectedLanguage.languageCode ==
                              languageData.languageCode
                          ? primaryColor
                          : context.scaffoldBackgroundColor,
                      elevation: 0,
                      side: BorderSide(width: 1, color: context.iconColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CachedImageWidget(
                            url: languageData.flag.validate(), height: 16),
                        4.width,
                        Text(languageData.name.validate().toUpperCase(),
                            style: secondaryTextStyle(
                                color: appStore.selectedLanguage.languageCode ==
                                        languageData.languageCode
                                    ? white
                                    : textSecondaryColorGlobal))
                      ],
                    ),
                  ).paddingOnly(
                      right: 8,
                      left: languageList().first.languageCode ==
                              languageData.languageCode
                          ? 16
                          : 0);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
//endregion
