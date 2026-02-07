import 'dart:async';
import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/component/responsive_container.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/forgot_password_screen.dart';
import 'package:booking_system_flutter/screens/auth/otp_login_screen.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../network/rest_apis.dart';

class SignInScreen extends StatefulWidget {
  final bool? isFromDashboard;
  final bool? isFromServiceBooking;
  final bool returnExpected;

  SignInScreen(
      {this.isFromDashboard,
      this.isFromServiceBooking,
      this.returnExpected = false});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isRemember = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRemember = getBoolAsync(IS_REMEMBERED);
    if (isRemember) {
      emailCont.text = getStringAsync(USER_EMAIL);
      passwordCont.text = getStringAsync(USER_PASSWORD);
    }

    /// For Demo Purpose
    if (await isIqonicProduct) {
      emailCont.text = DEFAULT_EMAIL;
      passwordCont.text = DEFAULT_PASS;
    }
  }

  //region Methods

  void _handleLogin() {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);
    Map<String, dynamic> request = {
      'email': emailCont.text.trim(),
      'password': passwordCont.text.trim(),
    };

    appStore.setLoading(true);
    try {
      final loginResponse = await loginUser(request, isSocialLogin: false);

      await saveUserData(loginResponse.userData!);

      await setValue(USER_PASSWORD, passwordCont.text);
      await setValue(IS_REMEMBERED, isRemember);
      await appStore.setLoginType(LOGIN_TYPE_USER);

      authService.verifyFirebaseUser();
      TextInput.finishAutofillContext();

      onLoginSuccessRedirection();
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  void googleSignIn() async {
    if (!appStore.isLoading) {
      appStore.setLoading(true);
      try {
        final googleUser = await authService
            .signInWithGoogle(context)
            .timeout(const Duration(seconds: 90), onTimeout: () {
          throw TimeoutException('Google Sign-In timed out. Please try again.');
        });
        String displayName = googleUser.displayName.validate().trim();
        String firstName = '';
        String lastName = '';
        if (displayName.isNotEmpty) {
          final parts = displayName.split(' ');
          if (parts.length >= 1) firstName = parts.first.trim();
          if (parts.length >= 2) lastName = parts.sublist(1).join(' ').trim();
        }
        // Backend requires non-empty first_name/last_name (e.g. NOT NULL)
        final emailLocal = googleUser.email
                ?.splitBefore('@')
                .replaceAll('.', '')
                .toLowerCase() ??
            'user';
        if (firstName.isEmpty)
          firstName = emailLocal.isNotEmpty ? emailLocal : 'User';
        if (lastName.isEmpty) lastName = 'User';

        Map<String, dynamic> request = {
          'first_name': firstName,
          'last_name': lastName,
          'email': googleUser.email,
          'username': googleUser.email
              .splitBefore('@')
              .replaceAll('.', '')
              .toLowerCase(),
          'social_image': googleUser.photoURL,
          'login_type': LOGIN_TYPE_GOOGLE,
        };
        var loginResponse = await loginUser(request, isSocialLogin: true);

        loginResponse.userData!.profileImage = googleUser.photoURL.validate();

        await saveUserData(loginResponse.userData!);
        appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        authService.verifyFirebaseUser();

        onLoginSuccessRedirection();
      } catch (e) {
        log(e.toString());
        if (e is PlatformException &&
            e.code == 'sign_in_failed' &&
            (e.message ?? '').contains('ApiException: 10')) {
          toast(
            'Google Sign-In is not configured. Add this app\'s SHA-1 in Firebase Console (see GOOGLE_SIGNIN_SETUP.md).',
          );
        } else {
          toast(e.toString());
        }
      } finally {
        appStore.setLoading(false);
      }
    }
  }

  void appleSign() async {
    if (!appStore.isLoading) {
      appStore.setLoading(true);

      await authService.appleSignIn().then((req) async {
        // Ensure first_name and last_name are not empty or null
        String email = req['email'] ??
            'unknown_${DateTime.now().millisecondsSinceEpoch}@apple.com';
        String firstName = req['first_name']?.toString().trim() ?? '';
        String lastName = req['last_name']?.toString().trim() ?? '';

        // Fallback if names are not available
        if (firstName.isEmpty || lastName.isEmpty) {
          final parts = email.split('@').first.split('.');
          firstName = parts.first.capitalizeFirstLetter();
          lastName =
              parts.length > 1 ? parts[1].capitalizeFirstLetter() : 'User';
        }

        req['first_name'] = firstName;
        req['last_name'] = lastName;

        await loginUser(req, isSocialLogin: true).then((value) async {
          await saveUserData(value.userData!);
          appStore.setLoginType(LOGIN_TYPE_APPLE);

          appStore.setLoading(false);
          authService.verifyFirebaseUser();

          onLoginSuccessRedirection();
        }).catchError((e) {
          appStore.setLoading(false);
          log(e.toString());
          throw e;
        });
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
    }
  }

  void otpSignIn() async {
    hideKeyboard(context);

    OTPLoginScreen().launch(context);
  }

  void onLoginSuccessRedirection() {
    afterBuildCreated(() {
      appStore.setLoading(false);
      if (widget.isFromServiceBooking.validate() ||
          widget.isFromDashboard.validate() ||
          widget.returnExpected.validate()) {
        if (widget.isFromDashboard.validate()) {
          push(DashboardScreen(redirectToBooking: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          finish(context, true);
        }
      } else {
        DashboardScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      }
    });
  }

//endregion

//region Widgets
  Widget _buildTopWidget() {
    return Container(
      child: Column(
        children: [
          Text("${language.lblLoginTitle}!", style: boldTextStyle(size: 20))
              .center(),
          16.height,
          Text(language.lblLoginSubTitle,
                  style: primaryTextStyle(size: 14),
                  textAlign: TextAlign.center)
              .center()
              .paddingSymmetric(horizontal: 32),
          32.height,
        ],
      ),
    );
  }

  Widget _buildRememberWidget() {
    return Column(
      children: [
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RoundedCheckBox(
              borderColor: context.primaryColor,
              checkedColor: context.primaryColor,
              isChecked: isRemember,
              text: language.rememberMe,
              textStyle: secondaryTextStyle(),
              size: 20,
              onTap: (value) async {
                await setValue(IS_REMEMBERED, isRemember);
                isRemember = !isRemember;
                setState(() {});
              },
            ),
            TextButton(
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
              child: Text(
                language.forgotPassword,
                style: boldTextStyle(
                    color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
            ).flexible(),
          ],
        ),
        24.height,
        AppButton(
          text: language.signIn,
          color: primaryColor,
          textColor: Colors.white,
          width: context.width() >= 600
              ? 400
              : context.width() - context.navigationBarHeight,
          onTap: () {
            _handleLogin();
          },
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                hideKeyboard(context);
                SignUpScreen().launch(context);
              },
              child: Text(
                language.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        // TextButton(
        //   onPressed: () {
        //     if (isAndroid) {
        //       if (getStringAsync(PROVIDER_PLAY_STORE_URL).isNotEmpty) {
        //         launchUrl(Uri.parse(getStringAsync(PROVIDER_PLAY_STORE_URL)), mode: LaunchMode.externalApplication);
        //       } else {
        //         launchUrl(Uri.parse('${getSocialMediaLink(LinkProvider.PLAY_STORE)}$PROVIDER_PACKAGE_NAME'), mode: LaunchMode.externalApplication);
        //       }
        //     } else if (isIOS) {
        //       if (getStringAsync(PROVIDER_APPSTORE_URL).isNotEmpty) {
        //         commonLaunchUrl(getStringAsync(PROVIDER_APPSTORE_URL));
        //       } else {
        //         commonLaunchUrl(IOS_LINK_FOR_PARTNER);
        //       }
        //     }
        //   },
        //   child: Text(language.lblRegisterAsPartner, style: boldTextStyle(color: primaryColor)),
        // )
      ],
    );
  }

  Widget _buildSocialWidget() {
    if (appConfigurationStore.socialLoginStatus) {
      return Column(
        children: [
          20.height,
          if ((appConfigurationStore.googleLoginStatus ||
                  appConfigurationStore.otpLoginStatus) ||
              (isIOS && appConfigurationStore.appleLoginStatus))
            Row(
              children: [
                Divider(color: context.dividerColor, thickness: 2).expand(),
                16.width,
                Text(language.lblOrContinueWith, style: secondaryTextStyle()),
                16.width,
                Divider(color: context.dividerColor, thickness: 2).expand(),
              ],
            ),
          24.height,
          if (appConfigurationStore.googleLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() >= 600
                  ? 400
                  : context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: GoogleLogoWidget(size: 16),
                  ),
                  Text(language.lblSignInWithGoogle,
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.center)
                      .expand(),
                ],
              ),
              onTap: googleSignIn,
            ),
          if (appConfigurationStore.googleLoginStatus) 16.height,
          if (appConfigurationStore.otpLoginStatus)
            AppButton(
              text: '',
              color: context.cardColor,
              padding: EdgeInsets.all(8),
              textStyle: boldTextStyle(),
              width: context.width() >= 600
                  ? 400
                  : context.width() - context.navigationBarHeight,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      boxShape: BoxShape.circle,
                    ),
                    child: ic_calling
                        .iconImage(size: 18, color: primaryColor)
                        .paddingAll(4),
                  ),
                  Text(language.lblSignInWithOTP,
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.center)
                      .expand(),
                ],
              ),
              onTap: otpSignIn,
            ),
          if (appConfigurationStore.otpLoginStatus) 16.height,
          if (isIOS)
            if (appConfigurationStore.appleLoginStatus)
              AppButton(
                text: '',
                color: context.cardColor,
                padding: EdgeInsets.all(8),
                textStyle: boldTextStyle(),
                width: context.width() >= 600
                    ? 400
                    : context.width() - context.navigationBarHeight,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        boxShape: BoxShape.circle,
                      ),
                      child: Icon(Icons.apple),
                    ),
                    Text(language.lblSignInWithApple,
                            style: boldTextStyle(size: 12),
                            textAlign: TextAlign.center)
                        .expand(),
                  ],
                ),
                onTap: appleSign,
              ),
        ],
      );
    } else {
      return Offstage();
    }
  }

//endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (widget.isFromServiceBooking.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
    } else if (widget.isFromDashboard.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor,
          statusBarIconBrightness: Brightness.light);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Navigator.of(context).canPop()
              ? Container(
                  margin: EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: BackWidget(iconColor: context.iconColor))
              : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  appStore.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Body(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Observer(builder: (context) {
                return ResponsiveContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (context.height() * 0.12).toInt().height,
                      _buildTopWidget(),
                      AutofillGroup(
                        child: Column(
                          children: [
                            AppTextField(
                              textFieldType: TextFieldType.EMAIL_ENHANCED,
                              controller: emailCont,
                              focus: emailFocus,
                              nextFocus: passwordFocus,
                              errorThisFieldRequired: language.requiredText,
                              decoration: inputDecoration(context,
                                  labelText: language.hintEmailTxt),
                              suffix:
                                  ic_message.iconImage(size: 10).paddingAll(14),
                              autoFillHints: [AutofillHints.email],
                            ),
                            16.height,
                            AppTextField(
                              textFieldType: TextFieldType.PASSWORD,
                              controller: passwordCont,
                              focus: passwordFocus,
                              obscureText: true,
                              suffixPasswordVisibleWidget:
                                  ic_show.iconImage(size: 10).paddingAll(14),
                              suffixPasswordInvisibleWidget:
                                  ic_hide.iconImage(size: 10).paddingAll(14),
                              decoration: inputDecoration(context,
                                  labelText: language.hintPasswordTxt),
                              autoFillHints: [AutofillHints.password],
                              isValidationRequired: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return language.requiredText;
                                } else if (val.length < 8 || val.length > 12) {
                                  return language.passwordLengthShouldBe;
                                }
                                return null;
                              },
                              onFieldSubmitted: (s) {
                                _handleLogin();
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildRememberWidget(),
                      if (!getBoolAsync(HAS_IN_REVIEW)) _buildSocialWidget(),
                      30.height,
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
