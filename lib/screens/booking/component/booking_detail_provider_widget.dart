import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../model/booking_data_model.dart';
import '../../../utils/model_keys.dart';
import '../../chat/user_chat_screen.dart';

class BookingDetailProviderWidget extends StatefulWidget {
  final UserData providerData;
  final bool canCustomerContact;
  final bool providerIsHandyman;
  final BookingData? bookingDetail;

  BookingDetailProviderWidget({
    required this.providerData,
    this.canCustomerContact = true,
    this.providerIsHandyman = true,
    this.bookingDetail,
  });

  @override
  BookingDetailProviderWidgetState createState() =>
      BookingDetailProviderWidgetState();
}

class BookingDetailProviderWidgetState
    extends State<BookingDetailProviderWidget> {
  UserData userData = UserData();
  bool isChattingAllow = true;
  int? flag;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    userData = widget.providerData;
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        border: appStore.isDarkMode
            ? Border.all(color: context.dividerColor)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Provider Info
          Row(
            children: [
              ImageBorder(
                src: widget.providerData.profileImage.validate(),
                height: 60,
              ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Marquee(
                        child: Text(
                          widget.providerData.displayName.validate(),
                          style: boldTextStyle(),
                        ),
                      ).flexible(),
                      16.width,
                      Image.asset(ic_verified, height: 16, color: Colors.green)
                          .visible(widget.providerData.isVerifyProvider == 1),
                    ],
                  ),
                  4.height,
                  Row(
                    children: [
                      Image.asset(
                        ic_star_fill,
                        height: 14,
                        fit: BoxFit.fitWidth,
                        color: getRatingBarColor(
                          widget.providerData.providersServiceRating
                              .validate()
                              .toInt(),
                        ),
                      ),
                      4.width,
                      Text(
                        widget.providerData.providersServiceRating
                            .validate()
                            .toStringAsFixed(1)
                            .toString(),
                        style:
                            boldTextStyle(color: textSecondaryColor, size: 14),
                      ),
                    ],
                  ),
                ],
              ).expand(),
            ],
          ),

          /// Chat Button - Always visible now
          16.height,
          Row(
            children: [
              AppButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ic_chat.iconImage(size: 18),
                    8.width,
                    Text(language.lblChat, style: boldTextStyle()),
                  ],
                ).fit(),
                width: context.width(),
                elevation: 0,
                color: context.scaffoldBackgroundColor,
                onTap: () async {
                  toast(language.pleaseWaitWhileWeLoadChatDetails);
                  UserData? user = await userService.getUserNull(
                      email: widget.providerData.email.validate());

                  if (user != null) {
                    Fluttertoast.cancel();

                    if (widget.bookingDetail != null) {
                      isChattingAllow = widget.bookingDetail!.status !=
                          BookingStatusKeys.pending;
                    }

                    UserChatScreen(
                      receiverUser: user,
                      isChattingAllow: isChattingAllow,
                    ).launch(context);
                  } else {
                    Fluttertoast.cancel();
                    toast(
                        "${widget.providerData.firstName} ${language.isNotAvailableForChat}");
                  }
                },
              ).expand(),
            ],
          ).paddingTop(8),
        ],
      ),
    );
  }
}
