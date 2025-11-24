import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/my_post_request_item_component.dart';
import 'package:booking_system_flutter/screens/jobRequest/create_post_request_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/shimmer/my_post_job_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';

class MyPostRequestListScreen extends StatefulWidget {
  @override
  _MyPostRequestListScreenState createState() =>
      _MyPostRequestListScreenState();
}

class _MyPostRequestListScreenState extends State<MyPostRequestListScreen> {
  late Future<List<PostJobData>> future;
  List<PostJobData> postJobList = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    getLocation();
  }

  Future<void> init() async {
    future = getPostJobList(
      page,
      postJobList: postJobList,
      lastPageCallBack: (val) {
        isLastPage = val;
      },
    );
    setState(() {});
  }

  void getLocation() {
    Geolocator.requestPermission().then((value) {
      if (value == LocationPermission.whileInUse ||
          value == LocationPermission.always) {
        Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        ).then((pos) {
          appStore.setLatitude(pos.latitude);
          appStore.setLongitude(pos.longitude);
          setState(() {});
        }).catchError(onError);
      }
    });
  }

  @override
  void dispose() {
    setStatusBarColor(
      Colors.transparent,
      statusBarIconBrightness:
          appStore.isDarkMode ? Brightness.light : Brightness.dark,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myPostJobList,
      child: Stack(
        children: [
          SnapHelperWidget<List<PostJobData>>(
            future: future,
            onSuccess: (data) {
              return AnimatedListView(
                itemCount: data.length,
                padding: EdgeInsets.only(top: 12, bottom: 70),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemBuilder: (_, i) {
                  final postJob = data[i];
                  return MyPostRequestItemComponent(
                    data: postJob,
                    callback: (v) {
                      appStore.setLoading(v);
                      if (v) {
                        page = 1;
                        init();
                      }
                    },
                  );
                },
                emptyWidget: NoDataWidget(
                  title: language.noPostJobFound,
                  subTitle: language.noPostJobFoundSubtitle,
                  imageWidget: EmptyStateWidget(),
                ),
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);
                    init();
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;
                  await init();
                  return await 2.seconds.delay;
                },
              );
            },
            loadingWidget: MyPostJobShimmer(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);
                  init();
                },
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
      bottomNavigationBar: AppButton(
        child: Text(language.requestNewJob, style: boldTextStyle(color: white)),
        color: context.primaryColor,
        width: context.width(),
        onTap: () async {
          bool? res = await CreatePostRequestScreen().launch(context);
          if (res ?? false) {
            page = 1;
            init();
          }
        },
      ).paddingAll(16),
    );
  }
}
