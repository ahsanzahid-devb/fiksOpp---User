import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/book_post_job_request_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/bidder_item_component.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/category_widget.dart';
import '../../component/empty_error_state_widget.dart';
import 'package:intl/intl.dart';

class MyPostDetailScreen extends StatefulWidget {
  final int postRequestId;
  final PostJobData? postJobData;
  final VoidCallback callback;

  MyPostDetailScreen({
    required this.postRequestId,
    this.postJobData,
    required this.callback,
  });

  @override
  _MyPostDetailScreenState createState() => _MyPostDetailScreenState();
}

class _MyPostDetailScreenState extends State<MyPostDetailScreen> {
  Future<PostJobDetailResponse>? future;

  @override
  void initState() {
    super.initState();
    LiveStream().on(LIVESTREAM_UPDATE_BIDER, (p0) {
      init();
      setState(() {});
    });
    init();
  }

  void init() async {
    future = getPostJobDetail(
        {PostJob.postRequestId: widget.postRequestId.validate()});
  }

  Widget titleWidget({
    required String title,
    required String detail,
    bool isReadMore = false,
    required TextStyle detailTextStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.validate(), style: secondaryTextStyle()),
        4.height,
        if (isReadMore)
          ReadMoreText(
            detail,
            style: detailTextStyle,
            colorClickableText: context.primaryColor,
          )
        else
          Text(detail.validate(), style: boldTextStyle(size: 12)),
        20.height,
      ],
    );
  }

  /// ✅ Updated Section
  Widget postJobDetailWidget({required PostJobData data}) {
    return Container(
      padding: EdgeInsets.all(16),
      width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.validate().isNotEmpty)
            titleWidget(
              title: language.postJobTitle,
              detail: data.title.validate(),
              detailTextStyle: boldTextStyle(),
            ),
          if (data.description.validate().isNotEmpty)
            titleWidget(
              title: language.postJobDescription,
              detail: data.description.validate(),
              detailTextStyle: primaryTextStyle(),
              isReadMore: true,
            ),
          if (data.service != null && data.service!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.category, style: secondaryTextStyle()),
                4.height,
                CategoryWidget(
                  categoryName: data.service!.first.categoryName,
                  subCategoryName: data.service!.first.subCategoryName,
                ),
                20.height,
              ],
            ),
          if (data.jobPrice != null && data.jobPrice != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.jobPrice, style: secondaryTextStyle()),
                4.height,
                PriceWidget(
                  price: data.jobPrice!,
                  isHourlyService: false,
                  color: textPrimaryColorGlobal,
                  isFreeService: false,
                  size: 14,
                ),
                20.height,
              ],
            ),

          /// ✅ Display price (as string) if available
          /// ✅ Display price (as string) if available
          if (data.price != null && data.price!.isNotEmpty && data.price != "0")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date / Price Info", style: secondaryTextStyle()),
                4.height,
                Text(
                  data.price!, // <-- this will show your input text
                  style: boldTextStyle(size: 14),
                ),
                20.height,
              ],
            ),
        ],
      ),
    );
  }

  Widget postJobServiceWidget({required List<ServiceData> serviceList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.services, style: boldTextStyle(size: LABEL_TEXT_SIZE))
            .paddingOnly(left: 16, right: 16),
        8.height,
        AnimatedListView(
          itemCount: serviceList.length,
          padding: EdgeInsets.all(8),
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CachedImageWidget(
                    url: data.attachments.validate().isNotEmpty
                        ? data.attachments!.first.validate()
                        : "",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                    radius: defaultRadius,
                  ),
                  16.width,
                  Text(
                    data.name.validate(),
                    style: primaryTextStyle(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).expand(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget bidderWidget(List<BidderData> bidderList,
      {required PostJobDetailResponse postJobDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.bidder,
          list: bidderList,
          onTap: () {},
        ).paddingSymmetric(horizontal: 16),
        AnimatedListView(
          itemCount: bidderList.length > 4
              ? bidderList.take(4).length
              : bidderList.length,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            return BidderItemComponent(
              data: bidderList[i],
              postRequestId: widget.postRequestId.validate(),
              postJobData: postJobDetailResponse.postRequestDetail!,
              postJobDetailResponse: postJobDetailResponse,
            );
          },
        ),
      ],
    );
  }

  Widget providerWidget(List<BidderData> bidderList, num? providerId) {
    try {
      BidderData? bidderData =
          bidderList.firstWhere((element) => element.providerId == providerId);
      UserData? user = bidderData.provider;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Text(language.assignedProvider,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          InkWell(
            onTap: () {
              ProviderInfoScreen(providerId: user.id.validate())
                  .launch(context);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CachedImageWidget(
                    url: user!.profileImage.validate(),
                    fit: BoxFit.cover,
                    height: 60,
                    width: 60,
                    circle: true,
                  ),
                  8.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName.validate(), style: boldTextStyle()),
                      4.height,
                      if (user.email.validate().isNotEmpty)
                        Text(user.email.validate(),
                            style: primaryTextStyle(size: 12)),
                      6.height,
                      if (user.providersServiceRating != null)
                        DisabledRatingBarWidget(
                          rating: user.providersServiceRating.validate(),
                          size: 14,
                        ),
                    ],
                  ).expand(),
                ],
              ),
            ),
          ),
        ],
      ).paddingOnly(left: 16, right: 16);
    } catch (e) {
      log(e);
      return Offstage();
    }
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_UPDATE_BIDER);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myPostDetail,
      child: SnapHelperWidget<PostJobDetailResponse>(
        future: future,
        onSuccess: (data) {
          return Stack(
            children: [
              AnimatedScrollView(
                padding: EdgeInsets.only(bottom: 60),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  postJobDetailWidget(data: data.postRequestDetail!)
                      .paddingAll(16),
                  if (data.postRequestDetail!.service.validate().isNotEmpty)
                    postJobServiceWidget(
                        serviceList:
                            data.postRequestDetail!.service.validate()),
                  if (data.postRequestDetail!.providerId != null)
                    providerWidget(data.biderData.validate(),
                        data.postRequestDetail!.providerId),
                  if (data.biderData.validate().isNotEmpty)
                    bidderWidget(data.biderData.validate(),
                        postJobDetailResponse: data),
                ],
                onSwipeRefresh: () async {
                  init();
                  setState(() {});
                  return await 2.seconds.delay;
                },
              ),
              if (data.postRequestDetail!.status == JOB_REQUEST_STATUS_ASSIGNED)
                Positioned(
                  bottom: 16 + MediaQuery.of(context).padding.bottom,
                  left: 16,
                  right: 16,
                  child: AppButton(
                    child: Text(language.bookTheService,
                        style: boldTextStyle(color: white)),
                    color: context.primaryColor,
                    onTap: () async {
                      BookPostJobRequestScreen(
                        postJobDetailResponse: data,
                        providerId:
                            data.postRequestDetail!.providerId.validate(),
                        jobPrice: data.postRequestDetail!.jobPrice.validate(),
                      ).launch(context);
                    },
                  ),
                ),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading)),
            ],
          );
        },
        loadingWidget: LoaderWidget(),
        errorBuilder: (error) => NoDataWidget(
          title: error,
          imageWidget: ErrorStateWidget(),
          retryText: language.reload,
          onRetry: () {
            appStore.setLoading(true);
            init();
          },
        ),
      ),
    );
  }
}
