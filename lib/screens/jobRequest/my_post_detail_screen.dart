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
import '../../component/responsive_container.dart';

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

  /// Post job detail card: all sections always visible with default values for null/empty.
  Widget postJobDetailWidget({required PostJobData data}) {
    String title = data.title.validate().isNotEmpty ? data.title! : '—';
    String description = data.description.validate().isNotEmpty ? data.description! : '—';
    String? categoryName = data.service.validate().isNotEmpty
        ? (data.service!.first.categoryName.validate().isNotEmpty ? data.service!.first.categoryName : null)
        : null;
    String? subCategoryName = data.service.validate().isNotEmpty
        ? (data.service!.first.subCategoryName.validate().isNotEmpty ? data.service!.first.subCategoryName : null)
        : null;
    num jobPrice = data.jobPrice ?? 0;
    String datePriceInfo = (data.price.validate().isNotEmpty && data.price != "0") ? data.price! : '—';

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
          titleWidget(
            title: language.postJobTitle,
            detail: title,
            detailTextStyle: boldTextStyle(),
          ),
          titleWidget(
            title: language.postJobDescription,
            detail: description,
            detailTextStyle: primaryTextStyle(),
            isReadMore: description.length > 80,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.category, style: secondaryTextStyle()),
              4.height,
              CategoryWidget(
                categoryName: categoryName ?? '—',
                subCategoryName: subCategoryName ?? '—',
              ),
              20.height,
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.jobPrice, style: secondaryTextStyle()),
              4.height,
              jobPrice > 0
                  ? PriceWidget(
                      price: jobPrice,
                      isHourlyService: false,
                      color: textPrimaryColorGlobal,
                      isFreeService: false,
                      size: 14,
                    )
                  : Text('—', style: boldTextStyle(size: 14)),
              20.height,
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date / Price Info", style: secondaryTextStyle()),
              4.height,
              Text(datePriceInfo, style: boldTextStyle(size: 14)),
              20.height,
            ],
          ),
        ],
      ),
    );
  }

  Widget postJobServiceWidget({required List<ServiceData> serviceList}) {
    final list = serviceList.validate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.services, style: boldTextStyle(size: LABEL_TEXT_SIZE))
            .paddingOnly(left: 16, right: 16),
        8.height,
        list.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No services added',
                  style: secondaryTextStyle(),
                ),
              )
            : AnimatedListView(
                itemCount: list.length,
                padding: EdgeInsets.all(8),
                shrinkWrap: true,
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemBuilder: (_, i) {
                  ServiceData data = list[i];
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
                          data.name.validate().isNotEmpty ? data.name! : '—',
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
    final list = bidderList.validate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.bidder,
          list: list,
          onTap: () {},
        ).paddingSymmetric(horizontal: 16),
        list.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No bidders yet',
                  style: secondaryTextStyle(),
                ),
              )
            : AnimatedListView(
                itemCount: list.length > 4 ? list.take(4).length : list.length,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemBuilder: (_, i) {
                  return BidderItemComponent(
                    data: list[i],
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
    if (providerId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Text(language.assignedProvider,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Text('Not assigned', style: secondaryTextStyle()),
          ),
        ],
      ).paddingOnly(left: 16, right: 16);
    }
    try {
      BidderData? bidderData =
          bidderList.firstWhere((element) => element.providerId == providerId);
      UserData? user = bidderData.provider;
      if (user == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(language.assignedProvider,
                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            16.height,
            Container(
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Text('—', style: secondaryTextStyle()),
            ),
          ],
        ).paddingOnly(left: 16, right: 16);
      }
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
                    url: user.profileImage.validate().isNotEmpty
                        ? user.profileImage!
                        : "",
                    fit: BoxFit.cover,
                    height: 60,
                    width: 60,
                    circle: true,
                  ),
                  8.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          user.displayName.validate().isNotEmpty
                              ? user.displayName!
                              : '—',
                          style: boldTextStyle()),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Text(language.assignedProvider,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Text('—', style: secondaryTextStyle()),
          ),
        ],
      ).paddingOnly(left: 16, right: 16);
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
              ResponsiveContainer(
                padding: EdgeInsets.only(bottom: 60, left: 16, right: 16),
                maxWidth: 800,
                child: AnimatedScrollView(
                  padding: EdgeInsets.zero,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    postJobDetailWidget(data: data.postRequestDetail!),
                    postJobServiceWidget(
                        serviceList:
                            data.postRequestDetail!.service.validate()),
                    providerWidget(
                        data.biderData.validate(),
                        data.postRequestDetail!.providerId),
                    bidderWidget(data.biderData.validate(),
                        postJobDetailResponse: data),
                  ],
                  onSwipeRefresh: () async {
                    init();
                    setState(() {});
                    return await 2.seconds.delay;
                  },
                ),
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
