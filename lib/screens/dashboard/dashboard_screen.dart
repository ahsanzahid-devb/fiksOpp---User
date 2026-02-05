import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/chat/chat_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/profile_fragment.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_request_list_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/voice_search_component.dart';
import '../../utils/app_configuration.dart';
import '../newDashboard/dashboard_1/dashboard_fragment_1.dart';
import '../newDashboard/dashboard_2/dashboard_fragment_2.dart';
import '../newDashboard/dashboard_3/dashboard_fragment_3.dart';
import '../newDashboard/dashboard_4/dashboard_fragment_4.dart';

class DashboardScreen extends StatefulWidget {
  final bool? redirectToBooking;

  DashboardScreen({this.redirectToBooking});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;
  bool isInterNetConnect = true;

  @override
  void initState() {
    super.initState();
    if (widget.redirectToBooking.validate(value: false)) {
      currentIndex = 2; // Booking is now at index 2 (after Home, My Jobs)
    }

    afterBuildCreated(() async {
      /// Changes System theme when changed
      if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(context.platformBrightness() == Brightness.dark);
      }

      View.of(context).platformDispatcher.onPlatformBrightnessChanged =
          () async {
        if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
          appStore.setDarkMode(
              MediaQuery.of(context).platformBrightness == Brightness.light);
        }
      };
    });

    /// Handle Firebase Notification click and redirect to that Service & BookDetail screen
    LiveStream().on(LIVESTREAM_FIREBASE, (value) {
      if (value == 3) {
        // Chat at 3 when enabled, else Profile at 3
        currentIndex = appConfigurationStore.isEnableChat ? 4 : 3;
        setState(() {});
      }
    });

    init();
  }

  void init() async {
    await 3.seconds.delay;
    if (getIntAsync(FORCE_UPDATE_USER_APP).getBoolInt()) {
      showForceUpdateDialog(context);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_FIREBASE);
  }

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      message: language.lblBackPressMsg,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: AnimatedOpacity(
            opacity: 1,
            duration: Duration(milliseconds: 500),
            child: [
              Observer(
                builder: (context) {
                  if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
                    return DashboardFragment1();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_2) {
                    return DashboardFragment2();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_3) {
                    return DashboardFragment3();
                  } else if (appConfigurationStore.userDashboardType ==
                      DASHBOARD_4) {
                    return DashboardFragment4();
                  } else {
                    return DashboardFragment();
                  }
                },
              ),
              Observer(
                  builder: (context) => appStore.isLoggedIn
                      ? MyPostRequestListScreen(isFromDashboard: true)
                      : SignInScreen(isFromDashboard: true)),
              Observer(
                  builder: (context) => appStore.isLoggedIn
                      ? BookingFragment()
                      : SignInScreen(isFromDashboard: true)),
              if (appConfigurationStore.isEnableChat)
                Observer(
                    builder: (context) => appStore.isLoggedIn
                        ? ChatListScreen()
                        : SignInScreen(isFromDashboard: true)),
              Observer(
                  builder: (context) => appStore.isLoggedIn
                      ? ProfileFragment()
                      : SignInScreen(isFromDashboard: true))
            ][currentIndex],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address search bar at the bottom - only show when on HOME tab (index 0)
            if (currentIndex == 0)
              Observer(
                builder: (context) {
                  return AppButton(
                    padding: EdgeInsets.all(0),
                    width: context.width(),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration:
                          boxDecorationDefault(color: context.cardColor),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ic_location.iconImage(
                              color: appStore.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                              size: 24),
                          8.width,
                          Text(
                            appStore.isCurrentLocation
                                ? getStringAsync(CURRENT_ADDRESS)
                                : language.lblLocationOff,
                            style: secondaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).expand(),
                          8.width,
                          Icon(Icons.keyboard_arrow_down,
                              size: 24,
                              color: appStore.isCurrentLocation
                                  ? primaryColor
                                  : context.iconColor),
                        ],
                      ),
                    ),
                    onTap: () async {
                      locationWiseService(context, () {
                        appStore.setLoading(true);

                        init();
                        setState(() {});
                      });
                    },
                  ).cornerRadiusWithClipRRect(28);
                },
              ).paddingSymmetric(horizontal: 16),
            16.height,
            Blur(
              blur: 30,
              borderRadius: radius(0),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: context.primaryColor.withValues(alpha: 0.02),
                  indicatorColor: context.primaryColor.withValues(alpha: 0.1),
                  labelTextStyle:
                      WidgetStateProperty.all(primaryTextStyle(size: 12)),
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  destinations: [
                    NavigationDestination(
                      icon: ic_home.iconImage(color: appTextSecondaryColor),
                      selectedIcon:
                          ic_home.iconImage(color: context.primaryColor),
                      label: language.home,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.work_outline,
                          color: appTextSecondaryColor),
                      selectedIcon:
                          Icon(Icons.work, color: context.primaryColor),
                      label: language.lblMyJobs,
                    ),
                    NavigationDestination(
                      icon: ic_ticket.iconImage(color: appTextSecondaryColor),
                      selectedIcon:
                          ic_ticket.iconImage(color: context.primaryColor),
                      label: language.booking,
                    ),
                    if (appConfigurationStore.isEnableChat)
                      NavigationDestination(
                        icon: ic_chat.iconImage(color: appTextSecondaryColor),
                        selectedIcon:
                            ic_chat.iconImage(color: context.primaryColor),
                        label: language.lblChat,
                      ),
                    Observer(
                      builder: (context) {
                        return NavigationDestination(
                          icon: (appStore.isLoggedIn &&
                                  appStore.userProfileImage.isNotEmpty)
                              ? IgnorePointer(
                                  ignoring: true,
                                  child: ImageBorder(
                                      src: appStore.userProfileImage,
                                      height: 26))
                              : ic_profile2.iconImage(
                                  color: appTextSecondaryColor),
                          selectedIcon: (appStore.isLoggedIn &&
                                  appStore.userProfileImage.isNotEmpty)
                              ? IgnorePointer(
                                  ignoring: true,
                                  child: ImageBorder(
                                      src: appStore.userProfileImage,
                                      height: 26))
                              : ic_profile2.iconImage(
                                  color: context.primaryColor),
                          label: language.profile,
                        );
                      },
                    ),
                  ],
                  onDestinationSelected: (index) {
                    currentIndex = index;
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Observer(builder: (context) {
          return VoiceSearchComponent().visible(appStore.isSpeechActivated);
        }),
      ),
    );
  }
}
