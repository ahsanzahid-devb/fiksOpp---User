import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../main.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/images.dart';
import '../../../auth/sign_in_screen.dart';
import '../../../jobRequest/createService/create_service_screen.dart';

class JobRequestDashboardComponent3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        image: DecorationImage(image: AssetImage(grid)),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 14.height,
          // Image.asset(people),
          // 14.height,
          Text(
            language.ifYouDidnTFind,
            style: boldTextStyle(color: black, size: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          14.height,
          TextButton(
            onPressed: () async {
              if (appStore.isLoggedIn) {
                CreateServiceScreen().launch(context);
              } else {
                setStatusBarColor(transparentColor,
                    delayInMilliSeconds: 100,
                    statusBarIconBrightness: appStore.isDarkMode
                        ? Brightness.light
                        : Brightness.dark);
                bool? res =
                    await SignInScreen(isFromDashboard: true).launch(context);

                if (res ?? false) {
                  CreateServiceScreen().launch(context);
                }
              }
            },
            child: Text(
              language.newRequest,
              style: boldTextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
