import 'dart:convert';

import 'package:fiksOpp/component/back_widget.dart';
import 'package:fiksOpp/component/base_scaffold_body.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/screens/auth/sign_in_screen.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/firebase_auth_phone_utils.dart';
import 'package:fiksOpp/utils/network_reachability.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../network/rest_apis.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../dashboard/dashboard_screen.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController numberController = TextEditingController();
  FocusNode _mobileNumberFocus = FocusNode();

  Country selectedCountry = defaultCountry();

  String otpCode = '';
  String verificationId = '';

  ValueNotifier _valueNotifier = ValueNotifier(true);

  bool isCodeSent = false;

  bool _otpVerifyInFlight = false;
  DateTime? _lastOtpVerificationFailureTime;
  String? _lastOtpVerificationFailureCode;

  int get _maxLocalPhoneDigits =>
      phoneAuthExpectedLocalDigitLength(selectedCountry);

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() => init());
  }

  Future<void> init() async {
    appStore.setLoading(false);
  }

  /// After Firebase accepts the phone credential, sync with your API and go to
  /// [DashboardScreen], or [SignInScreen] if the account is not registered yet.
  /// Used from manual OTP submit and from Android auto `verificationCompleted`.
  Future<void> _completeBackendOtpLogin({
    required UserCredential userCredential,
    required PhoneAuthCredential phoneCredential,
  }) async {
    if (!mounted) return;
    final request = <String, dynamic>{
      'username': numberController.text.trim(),
      'password': numberController.text.trim(),
      'login_type': LOGIN_TYPE_OTP,
      'uid': userCredential.user!.uid.validate(),
    };
    try {
      final loginResponse = await loginUser(request, isSocialLogin: true);
      if (!mounted) return;
      if (loginResponse.isUserExist.validate(value: true)) {
        await saveUserData(loginResponse.userData!);
        await appStore.setLoginType(LOGIN_TYPE_OTP);
        appStore.setLoading(false);
        if (!mounted) return;
        DashboardScreen(initialTabIndex: 0).launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        appStore.setLoading(false);
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        if (!mounted) return;
        SignInScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      }
    } catch (e) {
      if (mounted) {
        finish(context);
        toast(e.toString());
      }
      appStore.setLoading(false);
    }
  }

  //region Methods
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: language.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      showPhoneCode:
          true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountry = country;
        log(jsonEncode(selectedCountry.toJson()));
        setState(() {});
      },
    );
  }

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      final digitsOnly =
          numberController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length != _maxLocalPhoneDigits) {
        toast('Enter a valid phone number');
        return;
      }

      if (!await canReachIdentityToolkitHost()) {
        debugPrint(
            '[OtpLogin/PhoneAuth] identitytoolkit host unreachable (offline?)');
        toast(kPhoneAuthNeedsInternetMessage, print: true);
        return;
      }

      if (_otpVerifyInFlight) return;
      _otpVerifyInFlight = true;
      _lastOtpVerificationFailureTime = null;
      _lastOtpVerificationFailureCode = null;

      appStore.setLoading(true);

      toast(language.sendingOTP);

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          timeout: const Duration(seconds: 120),
          phoneNumber: firebasePhoneAuthE164(
            countryCallingCodeDigits: selectedCountry.phoneCode,
            localNumberRaw: numberController.text.trim(),
          ),
          verificationCompleted: (PhoneAuthCredential credential) async {
            if (!mounted) return;
            try {
              appStore.setLoading(true);
              toast(language.verified);
              final uc =
                  await FirebaseAuth.instance.signInWithCredential(credential);
              await _completeBackendOtpLogin(
                  userCredential: uc, phoneCredential: credential);
            } on FirebaseAuthException catch (e) {
              logFirebaseAuthException('otpLogin verificationCompleted', e);
              if (mounted) {
                toast(userFacingFirebaseAuthMessage(e), print: true);
              }
              appStore.setLoading(false);
            } catch (e, st) {
              debugPrint('[OtpLogin/PhoneAuth] verificationCompleted $e');
              debugPrintStack(stackTrace: st);
              appStore.setLoading(false);
              if (mounted) toast(e.toString(), print: true);
            } finally {
              _otpVerifyInFlight = false;
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            logFirebaseAuthException('otpLogin verificationFailed', e);
            appStore.setLoading(false);
            _otpVerifyInFlight = false;
            if (shouldSuppressRedundantPhoneAuthFailure(
              current: e,
              previousCode: _lastOtpVerificationFailureCode,
              previousFailureTime: _lastOtpVerificationFailureTime,
            )) {
              debugPrint(
                  '[OtpLogin/PhoneAuth] suppressed redundant failure after rate limit');
              return;
            }
            _lastOtpVerificationFailureTime = DateTime.now();
            _lastOtpVerificationFailureCode = e.code;
            if (e.code == 'invalid-phone-number') {
              toast(language.theEnteredCodeIsInvalidPleaseTryAgain,
                  print: true);
            } else {
              toast(userFacingFirebaseAuthMessage(e), print: true);
            }
          },
          codeSent: (String _verificationId, int? resendToken) async {
            _otpVerifyInFlight = false;
            toast(language.otpCodeIsSentToYourMobileNumber);

            appStore.setLoading(false);

            verificationId = _verificationId;

            if (verificationId.isNotEmpty) {
              isCodeSent = true;
              setState(() {});
            } else {
              //Handle
            }
          },
          codeAutoRetrievalTimeout: (String vid) {
            // Do not signOut or clear isCodeSent — user still needs manual SMS entry.
            debugPrint(
                '[OtpLogin/PhoneAuth] codeAutoRetrievalTimeout idLen=${vid.length}');
            if (verificationId.isEmpty && vid.isNotEmpty) {
              verificationId = vid;
              isCodeSent = true;
              setState(() {});
            }
          },
        );
      } on Exception catch (e) {
        log(e);
        _otpVerifyInFlight = false;
        appStore.setLoading(false);

        toast(e.toString(), print: true);
      }
    }
  }

  Future<void> submitOtp() async {
    log(otpCode);
    if (otpCode.validate().isNotEmpty) {
      if (otpCode.validate().length >= OTP_TEXT_FIELD_LENGTH) {
        hideKeyboard(context);
        appStore.setLoading(true);

        try {
          final PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verificationId, smsCode: otpCode);
          final UserCredential credentials =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await _completeBackendOtpLogin(
              userCredential: credentials, phoneCredential: credential);
        } on FirebaseAuthException catch (e) {
          logFirebaseAuthException('otpLogin submitOtp', e);
          appStore.setLoading(false);
          if (e.code == 'invalid-verification-code') {
            toast(language.theEnteredCodeIsInvalidPleaseTryAgain, print: true);
          } else {
            final msg = userFacingFirebaseAuthMessage(e);
            toast(msg.isNotEmpty ? msg : (e.message ?? e.toString()),
                print: true);
          }
        } on Exception catch (e, st) {
          debugPrint('[OtpLogin/submitOtp] $e');
          debugPrintStack(stackTrace: st);
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        }
      } else {
        toast(language.pleaseEnterValidOTP);
      }
    } else {
      toast(language.pleaseEnterValidOTP);
    }
  }

  // endregion

  Widget _buildMainWidget() {
    if (isCodeSent) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            72.height,
            OTPTextField(
              pinLength: OTP_TEXT_FIELD_LENGTH,
              textStyle: primaryTextStyle(),
              decoration: inputDecoration(context).copyWith(
                counter: Offstage(),
              ),
              onChanged: (s) {
                otpCode = s;
                log(otpCode);
              },
              onCompleted: (pin) {
                otpCode = pin;
                submitOtp();
              },
            ).fit(),
            30.height,
            AppButton(
              onTap: () {
                submitOtp();
              },
              text: language.confirm,
              color: primaryColor,
              textColor: Colors.white,
              width: context.width(),
            ),
          ],
        ),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Country code ...
                Container(
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: ValueListenableBuilder(
                      valueListenable: _valueNotifier,
                      builder: (context, value, child) => Row(
                        children: [
                          Text(
                            "+${selectedCountry.phoneCode}",
                            style: primaryTextStyle(size: 12),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: primaryColor,
                          )
                        ],
                      ).paddingOnly(left: 8),
                    ),
                  ),
                ).onTap(() => changeCountry()).fit(fit: BoxFit.cover),
                10.width,
                // Mobile number text field...
                AppTextField(
                  controller: numberController,
                  focus: _mobileNumberFocus,
                  textFieldType: TextFieldType.PHONE,
                  decoration: inputDecoration(context).copyWith(
                    hintText:
                        '${language.lblExample}: ${selectedCountry.example}',
                    hintStyle: secondaryTextStyle(),
                  ),
                  maxLength: _maxLocalPhoneDigits,
                  autoFocus: true,
                  onFieldSubmitted: (s) {
                    sendOTP();
                  },
                ).expand(),
              ],
            ),
          ),
          30.height,
          AppButton(
            onTap: () {
              sendOTP();
            },
            text: language.btnSendOtp,
            color: primaryColor,
            textColor: Colors.white,
            width: context.width(),
          ),
        ],
      );
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              isCodeSent ? language.confirmOTP : language.lblEnterPhnNumber,
              style: boldTextStyle(size: APP_BAR_TEXT_SIZE)),
          elevation: 0,
          backgroundColor: context.scaffoldBackgroundColor,
          leading: Navigator.of(context).canPop()
              ? BackWidget(iconColor: context.iconColor)
              : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  appStore.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Body(
          child: Container(
            padding: EdgeInsets.all(16),
            child: _buildMainWidget(),
          ),
        ),
      ),
    );
  }
}
