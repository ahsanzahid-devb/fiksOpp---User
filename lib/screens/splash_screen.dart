import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/screens/dashboard/dashboard_screen.dart';
import 'package:fiksOpp/screens/maintenance_mode_screen.dart';
import 'package:fiksOpp/utils/configs.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../component/loader_widget.dart';
import '../network/rest_apis.dart';
import 'walk_through_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool appNotSynced = false;

  void _slog(String message) {
    log('SPLASH | ${DateTime.now().toIso8601String()} | $message');
  }

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      _slog('afterBuildCreated()');
      setStatusBarColor(Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness:
              appStore.isDarkMode ? Brightness.light : Brightness.dark);
      init();
    });
  }

  Future<void> init() async {
    _slog('init() start');
    // Load saved language or use default
    String savedLanguage = getStringAsync('selected_language_code',
        defaultValue: DEFAULT_LANGUAGE);
    _slog('savedLanguage=$savedLanguage');
    await appStore.setLanguage(savedLanguage);
    _slog('appStore.setLanguage done');

    // Sync new configurations when app is open
    await setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
    _slog('LAST_APP_CONFIGURATION_SYNCED_TIME reset to 0');

    /// Set app configurations with a safety timeout so splash can't hang forever
    try {
      _slog(
          'getAppConfigurations start (isLoggedIn=${appStore.isLoggedIn}, userId=${appStore.userId})');
      await getAppConfigurations().timeout(const Duration(seconds: 20));
      _slog('getAppConfigurations success');
    } catch (e) {
      _slog('getAppConfigurations failed: $e');
      if (!await isNetworkAvailable()) {
        _slog('network not available');
        toast(errorInternetNotAvailable);
      } else {
        log(e);
        toast(e.toString());
      }
    }

    appStore.setLoading(false);
    _slog(
        'IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE=${getBoolAsync(IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)}');
    if (!getBoolAsync(IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)) {
      appNotSynced = true;
      _slog('appNotSynced=true (show reload)');
      setState(() {});
    } else {
      int themeModeIndex =
          getIntAsync(THEME_MODE_INDEX, defaultValue: THEME_MODE_SYSTEM);
      _slog('themeModeIndex=$themeModeIndex');
      if (themeModeIndex == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(
            MediaQuery.of(context).platformBrightness == Brightness.dark);
        _slog('darkMode set from system');
      }
      // Check if the user is unauthorized and logged in, then clear preferences and cached data.
      // This condition occurs when the user is marked as inactive from the admin panel,
      if (!appConfigurationStore.isUserAuthorized && appStore.isLoggedIn) {
        _slog('user unauthorized -> clearPreferences');
        await clearPreferences();

        // Clear cached wallet history if it exists and is not empty
        if (cachedWalletHistoryList != null &&
            cachedWalletHistoryList!.isNotEmpty)
          cachedWalletHistoryList!.clear();
      }

      if (appConfigurationStore.maintenanceModeStatus) {
        _slog('navigate -> MaintenanceModeScreen');
        MaintenanceModeScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        if (getBoolAsync(IS_FIRST_TIME, defaultValue: true)) {
          _slog('navigate -> WalkThroughScreen');
          WalkThroughScreen().launch(context,
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          _slog('navigate -> DashboardScreen(initialTabIndex:0)');
          DashboardScreen(initialTabIndex: 0).launch(context,
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            appStore.isDarkMode ? splash_background : splash_light_background,
            height: context.height(),
            width: context.width(),
            fit: BoxFit.cover,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(appLogo, height: 120, width: 120),
              32.height,
              if (appNotSynced)
                Observer(
                  builder: (_) => appStore.isLoading
                      ? LoaderWidget().center()
                      : TextButton(
                          child: Text(language.reload, style: boldTextStyle()),
                          onPressed: () {
                            appStore.setLoading(true);
                            init();
                          },
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
