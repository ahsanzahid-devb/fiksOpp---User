import 'package:fiksOpp/component/image_border_component.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/screens/auth/sign_in_screen.dart';
import 'package:fiksOpp/screens/chat/chat_list_screen.dart';
import 'package:fiksOpp/screens/dashboard/fragment/booking_fragment.dart';
import 'package:fiksOpp/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:fiksOpp/screens/dashboard/fragment/profile_fragment.dart';
import 'package:fiksOpp/screens/jobRequest/my_post_request_list_screen.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/images.dart';
import 'package:fiksOpp/utils/string_extensions.dart';
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
  /// When true, open on Bookings tab (index 2).
  final bool? redirectToBooking;

  /// Force initial tab (0=Home, 1=My Jobs, 2=Bookings, …). Used after login/signup to always land on Home.
  final int? initialTabIndex;

  DashboardScreen({this.redirectToBooking, this.initialTabIndex});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _defaultLocationLabel = 'Denmark';

  int currentIndex = 0;
  bool isInterNetConnect = true;

  bool _ignoreFirebaseStreamUntil = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      currentIndex = widget.initialTabIndex!.clamp(0, 4);
    } else if (widget.redirectToBooking.validate(value: false)) {
      currentIndex = 2;
    }
    _ignoreFirebaseStreamUntil = true;
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) _ignoreFirebaseStreamUntil = false;
    });

    afterBuildCreated(() async {
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

    LiveStream().on(LIVESTREAM_FIREBASE, (value) {
      if (_ignoreFirebaseStreamUntil) return;
      if (value == 3) {
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
                      ? MyPostRequestListScreen()
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
                                : _defaultLocationLabel,
                            style: secondaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).expand(),
                          8.width,
                          Icon(Icons.keyboard_arrow_down,
                              size: 24, color: primaryColor),
                        ],
                      ),
                    ),
                    // onTap: () async {
                    //   SearchServiceScreen().launch(context).then((value) {
                    //     setStatusBarColor(Colors.transparent,
                    //         statusBarIconBrightness: Brightness.dark);
                    //   }

                    //   );
                    // },
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
                      StreamBuilder<int>(
                        stream: chatServices.getTotalUnreadCount(
                            userId: appStore.uid.validate()),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          Widget chatIcon(Color color) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ic_chat.iconImage(color: color),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      height: 12,
                                      width: 12,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: primaryTextStyle(
                                          size: 6,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }

                          return NavigationDestination(
                            icon: chatIcon(appTextSecondaryColor),
                            selectedIcon: chatIcon(context.primaryColor),
                            label: language.lblChat,
                          );
                        },
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
