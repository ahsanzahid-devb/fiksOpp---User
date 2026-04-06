import 'package:fiksOpp/app_theme.dart';
import 'package:fiksOpp/locale/app_localizations.dart';
import 'package:fiksOpp/locale/language_en.dart';
import 'package:fiksOpp/locale/languages.dart';
import 'package:fiksOpp/model/booking_detail_model.dart';
import 'package:fiksOpp/model/get_my_post_job_list_response.dart';
import 'package:fiksOpp/model/material_you_model.dart';
import 'package:fiksOpp/model/notification_model.dart';
import 'package:fiksOpp/model/provider_info_response.dart';
import 'package:fiksOpp/model/remote_config_data_model.dart';
import 'package:fiksOpp/model/service_data_model.dart';
import 'package:fiksOpp/model/service_detail_response.dart';
import 'package:fiksOpp/model/user_data_model.dart';
import 'package:fiksOpp/model/user_wallet_history.dart';
import 'package:fiksOpp/screens/blog/model/blog_detail_response.dart';
import 'package:fiksOpp/screens/blog/model/blog_response_model.dart';
import 'package:fiksOpp/screens/helpDesk/model/help_desk_response.dart';
import 'package:fiksOpp/screens/splash_screen.dart';
import 'package:fiksOpp/services/auth_services.dart';
import 'package:fiksOpp/services/chat_services.dart';
import 'package:fiksOpp/services/user_services.dart';
import 'package:fiksOpp/store/app_configuration_store.dart';
import 'package:fiksOpp/store/app_store.dart';
import 'package:fiksOpp/store/filter_store.dart';
import 'package:fiksOpp/store/roles_and_permission_store.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/configs.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/deep_link_handler.dart';
import 'package:fiksOpp/utils/firebase_messaging_utils.dart';
import 'package:app_links/app_links.dart' as app_links;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'model/bank_list_response.dart';
import 'model/booking_data_model.dart';
import 'model/booking_status_model.dart';
import 'model/category_model.dart';
import 'model/coupon_list_model.dart';
import 'model/dashboard_model.dart';

// Background FCM: implementation in utils/firebase_background_handler.dart (registered from initFirebaseMessaging).
//region Mobx Stores
AppStore appStore = AppStore();
FilterStore filterStore = FilterStore();
AppConfigurationStore appConfigurationStore = AppConfigurationStore();
RolesAndPermissionStore rolesAndPermissionStore = RolesAndPermissionStore();
//endregion

//region Global Variables
BaseLanguage language = LanguageEn();
//endregion

//region Services
UserService userService = UserService();
AuthService authService = AuthService();
ChatServices chatServices = ChatServices();
RemoteConfigDataModel remoteConfigDataModel = RemoteConfigDataModel();
//endregion
//region Cached Response Variables for Dashboard Tabs
DashboardResponse? cachedDashboardResponse;
List<BookingData>? cachedBookingList;
List<CategoryData>? cachedCategoryList;
List<BookingStatusResponse>? cachedBookingStatusDropdown;
List<PostJobData>? cachedPostJobList;
List<WalletDataElement>? cachedWalletHistoryList;
List<ServiceData>? cachedServiceFavList;
List<UserData>? cachedProviderFavList;
List<UserData>? cachedHandymanList;
List<BlogData>? cachedBlogList;
List<RatingData>? cachedRatingList;
List<HelpDeskListData>? cachedHelpDeskListData;
List<NotificationData>? cachedNotificationList;
CouponListResponse? cachedCouponListResponse;
List<BankHistory>? cachedBankList;
List<(int blogId, BlogDetailResponse list)?> cachedBlogDetail = [];
List<(int serviceId, ServiceDetailResponse list)?> listOfCachedData = [];
List<(int providerId, ProviderInfoResponse list)?> cachedProviderList = [];
List<(int categoryId, List<CategoryData> list)?> cachedSubcategoryList = [];
List<(int bookingId, BookingDetailResponse list)?> cachedBookingDetailList = [];
//endregion

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    PendingDeepLink.initialUri = await app_links.AppLinks().getInitialLink();
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('AppLinks.getInitialLink: $e');
    }
  }

  try {
    await Firebase.initializeApp();
    initFirebaseMessaging();
    if (kReleaseMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase init failed: $e');
    }
  }

  passwordLengthGlobal = PASSWORD_MIN_LENGTH;
  appButtonBackgroundColorGlobal = primaryColor;
  defaultAppButtonTextColorGlobal = Colors.white;
  defaultRadius = 12;
  defaultBlurRadius = 0;
  defaultSpreadRadius = 0;
  textSecondaryColorGlobal = appTextSecondaryColor;
  textPrimaryColorGlobal = appTextPrimaryColor;
  defaultAppButtonElevation = 0;
  pageRouteTransitionDurationGlobal = 400.milliseconds;
  textBoldSizeGlobal = 14;
  textPrimarySizeGlobal = 14;
  textSecondarySizeGlobal = 12;

  try {
    await initialize();
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('initialize() failed: $e');
    }
  }

  localeLanguageList = languageList();

  // Initialize language before app starts
  try {
    String savedLanguageCode = getStringAsync('selected_language_code',
        defaultValue: DEFAULT_LANGUAGE);
    language = await AppLocalizations().load(Locale(savedLanguageCode));
    appStore.selectedLanguageCode = savedLanguageCode;
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Language load failed: $e');
    }
  }

  int themeModeIndex =
      getIntAsync(THEME_MODE_INDEX, defaultValue: THEME_MODE_SYSTEM);
  if (themeModeIndex == THEME_MODE_LIGHT) {
    appStore.setDarkMode(false);
  } else if (themeModeIndex == THEME_MODE_DARK) {
    appStore.setDarkMode(true);
  }

  defaultToastBackgroundColor =
      appStore.isDarkMode ? Colors.white : Colors.black;
  defaultToastTextColor = appStore.isDarkMode ? Colors.black : Colors.white;

  // Always run app so user never sees a blank white screen
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Cached so FutureBuilder is not reset on every rebuild (avoids blank screen).
  late final Future<Color> _materialYouFuture = getMaterialYouData();

  @override
  void initState() {
    super.initState();
    DeepLinkCoordinator.startForegroundSubscription(
        app_links.AppLinks().uriLinkStream);
  }

  @override
  void dispose() {
    DeepLinkCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RestartAppWidget(
      child: FutureBuilder<Color>(
        future: _materialYouFuture,
        builder: (_, snap) {
          // Always use a valid color so first frame is never blank (App Review fix).
          final color = snap.data ?? defaultPrimaryColor;
          return Observer(
            builder: (_) => MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              home: SplashScreen(),
              theme: AppTheme.lightTheme(color: color),
              darkTheme: AppTheme.darkTheme(color: color),
              themeMode: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              title: APP_NAME,
              supportedLocales: LanguageDataModel.languageLocales(),
              localizationsDelegates: [
                AppLocalizations(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return MediaQuery(
                  child: child ?? const SizedBox.shrink(),
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(1.0)),
                );
              },
              localeResolutionCallback: (locale, supportedLocales) => locale,
              locale: Locale(appStore.selectedLanguageCode),
            ),
          );
        },
      ),
    );
  }
}
