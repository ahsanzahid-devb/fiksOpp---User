import 'package:fiksOpp/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../main.dart';
import '../../../../utils/images.dart';
import '../../../auth/sign_in_screen.dart';
import '../../../jobRequest/createService/create_service_screen.dart';

class NewJobRequestDashboardComponent1 extends StatelessWidget {
  const NewJobRequestDashboardComponent1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        decorationImage: DecorationImage(
            image: AssetImage(imgNewPostJob1), fit: BoxFit.cover),
        borderRadius: BorderRadius.all(Radius.zero),
      ),
      width: context.width(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Text(
            language.postYourRequestAnd,
            style: boldTextStyle(color: white, size: 16),
          ),
          20.height,
          ElevatedButton(
            onPressed: () async {
              if (appStore.isLoggedIn) {
                CreateServiceScreen().launch(context);
              } else {
                setStatusBarColor(Colors.white,
                    statusBarIconBrightness: Brightness.dark);
                bool? res =
                    await SignInScreen(isFromDashboard: true).launch(context);

                if (res ?? false) {
                  CreateServiceScreen().launch(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: primaryColor, size: 20),
                8.width,
                Text(
                  language.newRequest,
                  style: boldTextStyle(color: primaryColor, size: 14),
                ),
              ],
            ),
          ),
          16.height,
        ],
      ),
    );
  }
}
