import 'package:fiksOpp/component/back_widget.dart';
import 'package:fiksOpp/component/loader_widget.dart';
import 'package:fiksOpp/component/responsive_container.dart';
import 'package:fiksOpp/component/selected_item_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/model/country_list_model.dart';
import 'package:fiksOpp/model/user_data_model.dart';
import 'package:fiksOpp/network/rest_apis.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/configs.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/images.dart';
import 'package:fiksOpp/utils/firebase_auth_phone_utils.dart';
import 'package:fiksOpp/utils/network_reachability.dart';
import 'package:fiksOpp/utils/string_extensions.dart';
import 'package:fiksOpp/screens/dashboard/dashboard_screen.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? countryCode;
  final bool isOTPLogin;
  final String? uid;
  final int? tokenForOTPCredentials;

  SignUpScreen(
      {Key? key,
      this.phoneNumber,
      this.isOTPLogin = false,
      this.countryCode,
      this.uid,
      this.tokenForOTPCredentials})
      : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Country selectedCountry = defaultCountry();

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isAcceptedTc = false;

  bool isFirstTimeValidation = true;
  ValueNotifier _valueNotifier = ValueNotifier(true);

  /// Email/password signup: Firebase SMS OTP must succeed before [registerUser].
  bool _phoneOtpVerifiedForSignup = false;

  /// Firebase Auth UID from the successful phone credential (sent to API as `uid` for server-side checks).
  String? _verifiedPhoneFirebaseUid;
  bool _signupOtpCodeSent = false;
  String _signupVerificationId = '';
  UserData? _pendingSignupData;
  bool _isCreatingUserAfterOtp = false;

  bool _signupPhoneVerifyInFlight = false;
  DateTime? _lastSignupVerificationFailureTime;
  String? _lastSignupVerificationFailureCode;

  @override
  void initState() {
    super.initState();
    mobileCont.addListener(_onSignupMobileOrCountryChanged);
    init();
  }

  void _onSignupMobileOrCountryChanged() {
    if (widget.isOTPLogin) return;
    if (!_phoneOtpVerifiedForSignup && !_signupOtpCodeSent) return;
    _resetSignupPhoneVerification();
    setState(() {});
  }

  void _resetSignupPhoneVerification() {
    _phoneOtpVerifiedForSignup = false;
    _verifiedPhoneFirebaseUid = null;
    _signupOtpCodeSent = false;
    _signupVerificationId = '';
    _pendingSignupData = null;
    _isCreatingUserAfterOtp = false;
  }

  int get _maxLocalPhoneDigits {
    final exampleDigits =
        selectedCountry.example.replaceAll(RegExp(r'[^0-9]'), '');
    if (exampleDigits.isNotEmpty) {
      var localDigits = exampleDigits;

      // Some country examples may include the country code; keep only local part.
      if (localDigits.startsWith(selectedCountry.phoneCode) &&
          localDigits.length > selectedCountry.phoneCode.length + 5) {
        localDigits = localDigits.substring(selectedCountry.phoneCode.length);
      }

      final baseLen = localDigits.length;
      if (baseLen >= 6) {
        // Allow optional leading trunk zero for countries where users type it.
        final adjustedLen = localDigits.startsWith('0') ? baseLen : baseLen + 1;
        return adjustedLen.clamp(6, 15);
      }
    }

    return (15 - selectedCountry.phoneCode.length).clamp(6, 15);
  }

  String? _inferIsoFromAddress(String addr) {
    final a = addr.toLowerCase();
    const hints = <String, String>{
      'karachi': 'PK',
      'lahore': 'PK',
      'islamabad': 'PK',
      'pakistan': 'PK',
      'norway': 'NO',
      'norge': 'NO',
      'united states': 'US',
      'usa': 'US',
      'united kingdom': 'GB',
      'uk': 'GB',
    };
    for (final e in hints.entries) {
      if (a.contains(e.key)) return e.value;
    }
    return null;
  }

  Future<bool> _validatePhoneRegionWithLocation() async {
    final phoneIso = selectedCountry.countryCode.toUpperCase();
    final cid = appStore.countryId;

    if (cid > 0) {
      try {
        final countries = await getCountryList();
        CountryListResponse? match;
        for (final c in countries) {
          if (c.id == cid) {
            match = c;
            break;
          }
        }
        final locCode = match?.code?.trim();
        if (locCode != null && locCode.isNotEmpty) {
          if (locCode.toUpperCase() != phoneIso) {
            toast(MSG_PHONE_REGION_MISMATCH_LOCATION);
            return false;
          }
        }
      } catch (e) {
        log(e);
      }
      return true;
    }

    final addr = getStringAsync(CURRENT_ADDRESS).toLowerCase().trim();
    if (addr.isEmpty) return true;
    final inferred = _inferIsoFromAddress(addr);
    if (inferred == null) return true;
    if (inferred != phoneIso) {
      toast(MSG_PHONE_REGION_MISMATCH_LOCATION);
      return false;
    }
    return true;
  }

  Future<void> _sendSignupOtp() async {
    if (widget.isOTPLogin) return;
    hideKeyboard(context);
    final mobile = mobileCont.text.trim();
    if (mobile.isEmpty) {
      toast(language.requiredText);
      return;
    }
    if (mobile.length > _maxLocalPhoneDigits) {
      toast('Enter a valid phone number');
      return;
    }
    if (appStore.isLoading) return;
    if (_signupPhoneVerifyInFlight) return;
    if (!await canReachIdentityToolkitHost()) {
      debugPrint('[SignUp/PhoneAuth] identitytoolkit host unreachable (offline?)');
      toast(kPhoneAuthNeedsInternetMessage, print: true);
      return;
    }
    _signupPhoneVerifyInFlight = true;
    _lastSignupVerificationFailureTime = null;
    _lastSignupVerificationFailureCode = null;
    appStore.setLoading(true);
    toast(language.sendingOTP);
    try {
       await FirebaseAuth.instance.verifyPhoneNumber(
        timeout: const Duration(seconds: 120),
        phoneNumber: '+${selectedCountry.phoneCode}${mobileCont.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted || widget.isOTPLogin) return;
          if (isAndroid) {
            try {
              final uc =
                  await FirebaseAuth.instance.signInWithCredential(credential);
              final uid = uc.user?.uid;
              await FirebaseAuth.instance.signOut();
              if (!mounted || uid == null || uid.isEmpty) {
                if (mounted) {
                  _signupPhoneVerifyInFlight = false;
                  appStore.setLoading(false);
                }
                return;
              }
              setState(() {
                _phoneOtpVerifiedForSignup = true;
                _verifiedPhoneFirebaseUid = uid;
                _signupOtpCodeSent = false;
                _signupVerificationId = '';
              });
              _signupPhoneVerifyInFlight = false;
              appStore.setLoading(false);
              toast(language.verified);
              await _completePendingSignupIfReady();
            } catch (e, st) {
              if (e is FirebaseAuthException) {
                logFirebaseAuthException('signup verificationCompleted', e);
                if (mounted) {
                  toast(userFacingFirebaseAuthMessage(e), print: true);
                }
              } else {
                debugPrint('[SignUp/PhoneAuth] verificationCompleted err=$e');
                debugPrintStack(stackTrace: st);
                if (mounted) toast(e.toString(), print: true);
              }
              if (mounted) {
                _signupPhoneVerifyInFlight = false;
                appStore.setLoading(false);
              }
            }
          } else {
            _signupPhoneVerifyInFlight = false;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          logFirebaseAuthException('signup verificationFailed', e);
          appStore.setLoading(false);
          _signupPhoneVerifyInFlight = false;
          if (shouldSuppressRedundantPhoneAuthFailure(
            current: e,
            previousCode: _lastSignupVerificationFailureCode,
            previousFailureTime: _lastSignupVerificationFailureTime,
          )) {
            debugPrint(
                '[SignUp/PhoneAuth] suppressed redundant failure after rate limit');
            return;
          }
          _lastSignupVerificationFailureTime = DateTime.now();
          _lastSignupVerificationFailureCode = e.code;
          if (e.code == 'invalid-phone-number') {
            toast('Invalid phone number format. Check country and number.',
                print: true);
          } else {
            toast(userFacingFirebaseAuthMessage(e), print: true);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          _signupPhoneVerifyInFlight = false;
          appStore.setLoading(false);
          _signupVerificationId = verificationId;
          if (_signupVerificationId.isNotEmpty) {
            setState(() {
              _signupOtpCodeSent = true;
            });
            toast(language.otpCodeIsSentToYourMobileNumber);
            final verified = await _openSignupOtpScreen();
            if (!mounted) return;
            if (!verified) {
              setState(() {
                _signupOtpCodeSent = false;
              });
            }
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Do not signOut here — it breaks iOS/Android manual SMS entry and can
          // surface Firebase "internal-error" on the next credential step.
          debugPrint(
              '[SignUp/PhoneAuth] codeAutoRetrievalTimeout idLen=${verificationId.length}');
          if (_signupVerificationId.isEmpty && verificationId.isNotEmpty) {
            _signupVerificationId = verificationId;
          }
        },
      );
    } on Exception catch (e) {
      log(e);
      _signupPhoneVerifyInFlight = false;
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  Future<bool> _openSignupOtpScreen() async {
    final result = await SignUpOtpVerificationScreen(
      onVerify: _confirmSignupOtp,
    ).launch<bool>(context);
    return result == true;
  }

  Future<bool> _confirmSignupOtp(String code) async {
    if (widget.isOTPLogin) return false;
    if (code.length < OTP_TEXT_FIELD_LENGTH) {
      toast(language.pleaseEnterValidOTP);
      return false;
    }
    hideKeyboard(context);
    if (appStore.isLoading) return false;
    appStore.setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _signupVerificationId,
        smsCode: code,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = uc.user?.uid;
      await FirebaseAuth.instance.signOut();
      if (!mounted) return false;
      if (uid == null || uid.isEmpty) {
        appStore.setLoading(false);
        toast(errorSomethingWentWrong);
        return false;
      }
      setState(() {
        _phoneOtpVerifiedForSignup = true;
        _verifiedPhoneFirebaseUid = uid;
        _signupOtpCodeSent = false;
        _signupVerificationId = '';
      });
      appStore.setLoading(false);
      toast(language.verified);
      await _completePendingSignupIfReady();
      return true;
    } on FirebaseAuthException catch (e) {
      logFirebaseAuthException('signup confirmOtp', e);
      appStore.setLoading(false);
      if (e.code == 'invalid-verification-code') {
        toast(language.theEnteredCodeIsInvalidPleaseTryAgain, print: true);
      } else {
        final msg = userFacingFirebaseAuthMessage(e);
        toast(msg.isNotEmpty ? msg : (e.message ?? e.toString()), print: true);
      }
      return false;
    } on Exception catch (e, st) {
      debugPrint('[SignUp/PhoneAuth] confirmOtp err=$e');
      debugPrintStack(stackTrace: st);
      appStore.setLoading(false);
      toast(e.toString(), print: true);
      return false;
    }
  }

  void init() async {
    if (widget.phoneNumber != null) {
      selectedCountry = Country.parse(
          widget.countryCode.validate(value: selectedCountry.countryCode));

      mobileCont.text =
          widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
      passwordCont.text =
          widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
      userNameCont.text =
          widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  //region Logic
  String buildMobileNumber() {
    if (mobileCont.text.isEmpty) {
      return '';
    } else {
      return '${selectedCountry.phoneCode}-${mobileCont.text.trim()}';
    }
  }

  Future<void> registerWithOTP() async {
    hideKeyboard(context);

    if (appStore.isLoading) return;

    if (formKey.currentState!.validate()) {
      if (isAcceptedTc) {
        formKey.currentState!.save();
        if (!await _validatePhoneRegionWithLocation()) {
          return;
        }
        appStore.setLoading(true);

        UserData userResponse = UserData()
          ..username = widget.phoneNumber.validate().trim()
          ..loginType = LOGIN_TYPE_OTP
          ..contactNumber = buildMobileNumber()
          ..email = emailCont.text.trim()
          ..firstName = fNameCont.text.trim()
          ..lastName = lNameCont.text.trim()
          ..userType = USER_TYPE_USER
          ..uid = widget.uid.validate()
          ..password = widget.phoneNumber.validate().trim();

        /// Link OTP login with Email Auth
        if (widget.tokenForOTPCredentials != null) {
          try {
            AuthCredential credential = PhoneAuthProvider.credentialFromToken(
                widget.tokenForOTPCredentials!);
            UserCredential userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);

            AuthCredential emailAuthCredential = EmailAuthProvider.credential(
                email: emailCont.text.trim(),
                password: DEFAULT_FIREBASE_PASSWORD);
            userCredential.user!.linkWithCredential(emailAuthCredential);
          } catch (e) {
            print(e);
          }
        }

        await createUsers(tempRegisterData: userResponse);
      }
    }
  }

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
        if (!widget.isOTPLogin) {
          _resetSignupPhoneVerification();
        }
        setState(() {});
      },
    );
  }

  Future<void> registerUser() async {
    hideKeyboard(context);

    if (appStore.isLoading) return;

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      /// If Terms and condition is Accepted then only the user will be registered
      if (isAcceptedTc) {
        if (!await _validatePhoneRegionWithLocation()) {
          return;
        }

        /// Build pending request; account is created only after OTP verification success.
        _pendingSignupData = UserData()
          ..contactNumber = buildMobileNumber()
          ..firstName = fNameCont.text.trim()
          ..lastName = lNameCont.text.trim()
          ..userType = USER_TYPE_USER
          ..username = userNameCont.text.trim()
          ..email = emailCont.text.trim()
          ..password = passwordCont.text.trim();

        await _sendSignupOtp();
      } else {
        toast(language.termsConditionsAccept);
      }
    } else {
      isFirstTimeValidation = false;
      setState(() {});
    }
  }

  Future<void> _completePendingSignupIfReady() async {
    if (_isCreatingUserAfterOtp) return;
    final pending = _pendingSignupData;
    final uid = _verifiedPhoneFirebaseUid.validate();
    if (pending == null || uid.isEmpty) return;

    _isCreatingUserAfterOtp = true;
    _pendingSignupData = null;
    pending.uid = uid;

    appStore.setLoading(true);
    await createUsers(tempRegisterData: pending);
    _isCreatingUserAfterOtp = false;
  }

  /// API often returns "check / verify your email" even when the client logs the user in; avoid that confusing snackbar on opening home.
  bool _registerMessageIsEmailVerificationOnly(String message) {
    final m = message.toLowerCase().trim();
    if (m.isEmpty) return false;

    final emailTopic = m.contains('email') ||
        m.contains('e-post') ||
        m.contains('e-mail') ||
        (m.contains('verify your') && m.contains('mail'));

    final verificationCue = m.contains('verif') ||
        m.contains('bekreft') ||
        m.contains('check your') ||
        m.contains('confirmation') ||
        (m.contains('sent') && m.contains('link'));

    if (m.contains('verification mail')) return true;
    return emailTopic && verificationCue;
  }

  Future<void> createUsers({required UserData tempRegisterData}) async {
    await createUser(tempRegisterData.toJson()).then((registerResponse) async {
      registerResponse.userData!.password = passwordCont.text.trim();

      appStore.setLoading(false);
      final serverMsg = registerResponse.message.validate();
      if (serverMsg.isNotEmpty &&
          _registerMessageIsEmailVerificationOnly(serverMsg)) {
        toast(MSG_SIGNUP_WELCOME);
      } else if (serverMsg.isNotEmpty) {
        toast(serverMsg);
      } else {
        toast(MSG_SIGNUP_WELCOME);
      }
      await saveUserData(registerResponse.userData!);

      DashboardScreen(initialTabIndex: 0).launch(context,
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    }).catchError((e, st) {
      debugPrint('[SignUp/register] createUser failed: $e');
      debugPrintStack(stackTrace: st);
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  //endregion

  //region Widget
  Widget _buildTopWidget() {
    return Column(
      children: [
        (context.height() * 0.06).toInt().height,
        Container(
          height: 80,
          width: 80,
          padding: EdgeInsets.all(16),
          child: ic_profile2.iconImage(color: Colors.white),
          decoration:
              boxDecorationDefault(shape: BoxShape.circle, color: primaryColor),
        ),
        16.height,
        Text(language.lblHelloUser, style: boldTextStyle(size: 22)).center(),
        16.height,
        Text(language.lblSignUpSubTitle,
                style: secondaryTextStyle(size: 14),
                textAlign: TextAlign.center)
            .center()
            .paddingSymmetric(horizontal: 32),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormWidget() {
    // safeAreaTop: false — default SafeArea would apply full status-bar inset here,
    // adding a large empty gap between the subtitle and the first field.
    return ResponsiveContainer(
      safeAreaTop: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 32.height,
          AppTextField(
            textFieldType: TextFieldType.NAME,
            controller: fNameCont,
            focus: fNameFocus,
            nextFocus: lNameFocus,
            errorThisFieldRequired: language.requiredText,
            decoration:
                inputDecoration(context, labelText: language.hintFirstNameTxt),
            suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
          ),
          16.height,
          AppTextField(
            textFieldType: TextFieldType.NAME,
            controller: lNameCont,
            focus: lNameFocus,
            nextFocus: userNameFocus,
            errorThisFieldRequired: language.requiredText,
            decoration:
                inputDecoration(context, labelText: language.hintLastNameTxt),
            suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
          ),
          16.height,
          AppTextField(
            textFieldType: TextFieldType.USERNAME,
            controller: userNameCont,
            focus: userNameFocus,
            nextFocus: emailFocus,
            readOnly: widget.isOTPLogin.validate() ? widget.isOTPLogin : false,
            errorThisFieldRequired: language.requiredText,
            decoration:
                inputDecoration(context, labelText: language.hintUserNameTxt),
            suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
          ),
          16.height,
          AppTextField(
            textFieldType: TextFieldType.EMAIL_ENHANCED,
            controller: emailCont,
            focus: emailFocus,
            errorThisFieldRequired: language.requiredText,
            nextFocus: mobileFocus,
            decoration:
                inputDecoration(context, labelText: language.hintEmailTxt),
            suffix: ic_message.iconImage(size: 10).paddingAll(14),
          ),
          16.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: textSecondaryColorGlobal,
                        )
                      ],
                    ).paddingOnly(left: 8),
                  ),
                ),
              ).onTap(() => changeCountry()),
              10.width,
              // Mobile number text field...
              AppTextField(
                textFieldType:
                    isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                controller: mobileCont,
                focus: mobileFocus,
                errorThisFieldRequired: language.requiredText,
                nextFocus: passwordFocus,
                decoration: inputDecoration(context,
                        labelText: "${language.hintContactNumberTxt}")
                    .copyWith(
                  hintText:
                      '${language.lblExample}: ${selectedCountry.example}',
                  hintStyle: secondaryTextStyle(),
                ),
                maxLength: _maxLocalPhoneDigits,
                suffix: ic_calling.iconImage(size: 10).paddingAll(14),
              ).expand(),
            ],
          ),
          8.height,
          if (!widget.isOTPLogin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                4.height,
                AppTextField(
                  textFieldType: TextFieldType.PASSWORD,
                  controller: passwordCont,
                  focus: passwordFocus,
                  obscureText: true,
                  readOnly:
                      widget.isOTPLogin.validate() ? widget.isOTPLogin : false,
                  suffixPasswordVisibleWidget:
                      ic_show.iconImage(size: 10).paddingAll(14),
                  suffixPasswordInvisibleWidget:
                      ic_hide.iconImage(size: 10).paddingAll(14),
                  errorThisFieldRequired: language.requiredText,
                  decoration: inputDecoration(context,
                      labelText: language.hintPasswordTxt),
                  isValidationRequired: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return language.requiredText;
                    } else if (val.length < PASSWORD_MIN_LENGTH ||
                        val.length > PASSWORD_MAX_LENGTH) {
                      return language.passwordLengthShouldBe;
                    }
                    return null;
                  },
                  onFieldSubmitted: (s) {},
                ),
                20.height,
              ],
            ),
          _buildTcAcceptWidget(),
          8.height,
          AppButton(
            text: language.signUp,
            color: primaryColor,
            textColor: Colors.white,
            width: context.width() >= 600
                ? 400
                : context.width() - context.navigationBarHeight,
            onTap: () {
              if (widget.isOTPLogin) {
                registerWithOTP();
              } else {
                registerUser();
              }
            },
          ),
        ],
      ),
    );
  }

  static const String _privacyPolicyUrl =
      'https://fiksopp.com/personvernerklaering-for-fiksopp/';
  static const String _termsAndConditionsUrl =
      'https://fiksopp.com/brukeravtale-for-fiksopp/';

  Widget _buildTcAcceptWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SelectedItemWidget(isSelected: isAcceptedTc).onTap(() async {
          isAcceptedTc = !isAcceptedTc;
          setState(() {});
        }),
        16.width,
        RichTextWidget(
          list: [
            TextSpan(
                text: '${language.lblAgree} ', style: secondaryTextStyle()),
            TextSpan(
              text: language.lblTermsOfService,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final url =
                      appConfigurationStore.termConditions.validate().isNotEmpty
                          ? appConfigurationStore.termConditions
                          : _termsAndConditionsUrl;
                  checkIfLink(context, url, title: language.termsCondition);
                },
            ),
            TextSpan(text: ' & ', style: secondaryTextStyle()),
            TextSpan(
              text: language.privacyPolicy,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final url =
                      appConfigurationStore.privacyPolicy.validate().isNotEmpty
                          ? appConfigurationStore.privacyPolicy
                          : _privacyPolicyUrl;
                  checkIfLink(context, url, title: language.privacyPolicy);
                },
            ),
          ],
        ).flexible(flex: 2),
      ],
    ).paddingSymmetric(vertical: 16);
  }

  Widget _buildFooterWidget() {
    return Column(
      children: [
        // 16.height,
        RichTextWidget(
          list: [
            TextSpan(
                text: "${language.alreadyHaveAccountTxt} ",
                style: secondaryTextStyle()),
            TextSpan(
              text: language.signIn,
              style: boldTextStyle(color: primaryColor, size: 14),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  finish(context);
                },
            ),
          ],
        ),
        20.height,
      ],
    );
  }

  @override
  void dispose() {
    mobileCont.removeListener(_onSignupMobileOrCountryChanged);
    super.dispose();
  }

  //endregion

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: transparentColor,
          leading: Container(
              margin: EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: BackWidget(iconColor: context.iconColor)),
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  appStore.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarColor: context.scaffoldBackgroundColor),
        ),
        body: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Form(
              key: formKey,
              autovalidateMode: isFirstTimeValidation
                  ? AutovalidateMode.disabled
                  : AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTopWidget(),
                    _buildFormWidget(),
                    _buildFooterWidget(),
                  ],
                ),
              ),
            ),
            Observer(
                builder: (_) =>
                    LoaderWidget().center().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}

class SignUpOtpVerificationScreen extends StatefulWidget {
  final Future<bool> Function(String code) onVerify;

  const SignUpOtpVerificationScreen({Key? key, required this.onVerify})
      : super(key: key);

  @override
  State<SignUpOtpVerificationScreen> createState() =>
      _SignUpOtpVerificationScreenState();
}

class _SignUpOtpVerificationScreenState
    extends State<SignUpOtpVerificationScreen> {
  String _otpCode = '';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_otpCode.length < OTP_TEXT_FIELD_LENGTH) {
      toast(language.pleaseEnterValidOTP);
      return;
    }
    setState(() => _isSubmitting = true);
    final ok = await widget.onVerify(_otpCode);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) finish(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CONFIRM_OTP_BUTTON)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OTPTextField(
              pinLength: OTP_TEXT_FIELD_LENGTH,
              textStyle: primaryTextStyle(),
              decoration: inputDecoration(context).copyWith(
                counter: const Offstage(),
              ),
              onChanged: (s) => _otpCode = s,
              onCompleted: (pin) => _otpCode = pin,
            ).fit(),
            20.height,
            AppButton(
              text: CONFIRM_OTP_BUTTON,
              color: primaryColor,
              textColor: Colors.white,
              width: context.width(),
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
