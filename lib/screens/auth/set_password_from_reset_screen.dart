import 'package:fiksOpp/component/base_scaffold_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/network/rest_apis.dart';
import 'package:fiksOpp/screens/auth/sign_in_screen.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/images.dart';
import 'package:fiksOpp/utils/model_keys.dart';
import 'package:fiksOpp/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Opened from email / deep link after forgot-password. Backend must accept
/// `reset-password` POST: email, token, password, password_confirmation (typical Laravel).
class SetPasswordFromResetScreen extends StatefulWidget {
  final String resetToken;
  final String? prefilledEmail;

  const SetPasswordFromResetScreen({
    Key? key,
    required this.resetToken,
    this.prefilledEmail,
  }) : super(key: key);

  @override
  State<SetPasswordFromResetScreen> createState() =>
      _SetPasswordFromResetScreenState();
}

class _SetPasswordFromResetScreenState extends State<SetPasswordFromResetScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passCont = TextEditingController();
  final TextEditingController pass2Cont = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail.validate().isNotEmpty) {
      emailCont.text = widget.prefilledEmail!;
    } else {
      emailCont.text = getStringAsync(USER_EMAIL);
    }
  }

  @override
  void dispose() {
    emailCont.dispose();
    passCont.dispose();
    pass2Cont.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    hideKeyboard(context);
    if (!formKey.currentState!.validate()) return;
    if (passCont.text.trim() != pass2Cont.text.trim()) {
      toast(language.passwordNotMatch);
      return;
    }

    appStore.setLoading(true);
    final req = {
      UserKeys.email: emailCont.text.trim(),
      'token': widget.resetToken,
      UserKeys.password: passCont.text.trim(),
      'password_confirmation': pass2Cont.text.trim(),
    };
    try {
      final res = await resetPasswordWithToken(req);
      appStore.setLoading(false);
      toast(res.message.validate());
      SignInScreen().launch(context, isNewTask: true);
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.resetPassword,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.lblChangePwdTitle, style: secondaryTextStyle()),
              24.height,
              AppTextField(
                textFieldType: TextFieldType.EMAIL_ENHANCED,
                controller: emailCont,
                errorThisFieldRequired: language.requiredText,
                decoration: inputDecoration(context,
                    labelText: language.hintEmailTxt),
              ),
              16.height,
              AppTextField(
                textFieldType: TextFieldType.PASSWORD,
                controller: passCont,
                obscureText: true,
                suffixPasswordVisibleWidget:
                    ic_show.iconImage(size: 10).paddingAll(14),
                suffixPasswordInvisibleWidget:
                    ic_hide.iconImage(size: 10).paddingAll(14),
                decoration: inputDecoration(context,
                    labelText: language.hintNewPasswordTxt),
                isValidationRequired: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return language.requiredText;
                  if (val.length < passwordLengthGlobal ||
                      val.length > 12) {
                    return language.passwordLengthShouldBe;
                  }
                  return null;
                },
              ),
              16.height,
              AppTextField(
                textFieldType: TextFieldType.PASSWORD,
                controller: pass2Cont,
                obscureText: true,
                suffixPasswordVisibleWidget:
                    ic_show.iconImage(size: 10).paddingAll(14),
                suffixPasswordInvisibleWidget:
                    ic_hide.iconImage(size: 10).paddingAll(14),
                decoration: inputDecoration(context,
                    labelText: language.hintReenterPasswordTxt),
                isValidationRequired: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return language.requiredText;
                  if (val != passCont.text) return language.passwordNotMatch;
                  return null;
                },
              ),
              32.height,
              AppButton(
                text: language.resetPassword,
                color: primaryColor,
                width: context.width(),
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
