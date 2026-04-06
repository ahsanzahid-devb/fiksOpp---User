import 'dart:async';

import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/screens/dashboard/dashboard_screen.dart';
import 'package:fiksOpp/screens/maintenance_mode_screen.dart';
import 'package:fiksOpp/utils/configs.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/deep_link_handler.dart';
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
  Timer? _lateConfigTimer;

  static const int _configFetchMaxAttempts = 3;
  static const Duration _configFetchTimeoutPerAttempt =
      Duration(seconds: 45);

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
    _lateConfigTimer?.cancel();
    _lateConfigTimer = null;

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

    try {
      await _fetchAppConfigurationsWithRetries();
    } catch (e) {
      _slog('getAppConfigurations failed after retries: $e');
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
      _slog('appNotSynced=true (show reload or wait for late response)');
      setState(() {});
      _startLateConfigurationWatcher();
    } else {
      await _navigateFromSplashAfterConfig();
    }
  }

  /// Retries slow / cold-start API; a single [Future.timeout] does not cancel HTTP,
  /// so the server can still respond after the timeout and write prefs without the UI noticing.
  Future<void> _fetchAppConfigurationsWithRetries() async {
    Object? lastError;
    for (var attempt = 1; attempt <= _configFetchMaxAttempts; attempt++) {
      try {
        _slog(
            'getAppConfigurations attempt $attempt/$_configFetchMaxAttempts (isLoggedIn=${appStore.isLoggedIn}, userId=${appStore.userId})');
        await getAppConfigurations().timeout(_configFetchTimeoutPerAttempt);
        _slog('getAppConfigurations success on attempt $attempt');
        return;
      } catch (e) {
        lastError = e;
        _slog('getAppConfigurations attempt $attempt failed: $e');
        if (attempt < _configFetchMaxAttempts) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    if (lastError != null) {
      throw lastError!;
    }
  }

  void _startLateConfigurationWatcher() {
    _lateConfigTimer?.cancel();
    var ticks = 0;
    const maxTicks = 60; // ~30s at 500ms — covers straggler HTTP after timeout
    _lateConfigTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      ticks++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (getBoolAsync(IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)) {
        timer.cancel();
        _lateConfigTimer = null;
        _slog('late configuration sync detected -> continue from splash');
        appNotSynced = false;
        setState(() {});
        _navigateFromSplashAfterConfig();
      } else if (ticks >= maxTicks) {
        timer.cancel();
        _lateConfigTimer = null;
      }
    });
  }

  Future<void> _navigateFromSplashAfterConfig() async {
    if (!mounted) return;

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
          cachedWalletHistoryList!.isNotEmpty) {
        cachedWalletHistoryList!.clear();
      }
    }

    if (!mounted) return;

    if (appConfigurationStore.maintenanceModeStatus) {
      _slog('navigate -> MaintenanceModeScreen');
      MaintenanceModeScreen().launch(context,
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      DeepLinkCoordinator.consumeInitialUriIfAny();
    } else {
      if (getBoolAsync(IS_FIRST_TIME, defaultValue: true)) {
        _slog('navigate -> WalkThroughScreen');
        WalkThroughScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        DeepLinkCoordinator.consumeInitialUriIfAny();
      } else {
        _slog('navigate -> DashboardScreen(initialTabIndex:0)');
        DashboardScreen(initialTabIndex: 0).launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        DeepLinkCoordinator.consumeInitialUriIfAny();
      }
    }
  }

  @override
  void dispose() {
    _lateConfigTimer?.cancel();
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
