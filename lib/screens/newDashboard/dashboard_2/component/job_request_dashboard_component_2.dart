import 'package:fiksOpp/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../main.dart';
import '../../../../utils/images.dart';
import '../../../auth/sign_in_screen.dart';
import '../../../jobRequest/createService/create_service_screen.dart';

class JobRequestDashboardComponent2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        image: DecorationImage(
            image: AssetImage(grid), fit: BoxFit.cover, opacity: 0.3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.33, 0.65, 0.99],
          colors: [
            Color(0xFF4647a0),
            Color(0xFF36377c),
            Color(0xFF272759),
          ],
        ),
      ),
      child: Column(
        children: [
          16.height,
          Text(
            language.ifYouDidnTFind,
            style: primaryTextStyle(size: 14, color: black),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
