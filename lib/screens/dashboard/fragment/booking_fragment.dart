import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/model/booking_list_model.dart'; // For Handyman
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_item_component.dart';
import 'package:booking_system_flutter/screens/booking/shimmer/booking_shimmer.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_detail_screen.dart';
import 'package:booking_system_flutter/utils/configs.dart'; // For DOMAIN_URL
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../../store/filter_store.dart';
import '../../booking_filter/booking_filter_screen.dart';
import '../../../component/responsive_container.dart';

class BookingFragment extends StatefulWidget {
  @override
  _BookingFragmentState createState() => _BookingFragmentState();
}

class _BookingFragmentState extends State<BookingFragment> {
  UniqueKey keyForList = UniqueKey();

  ScrollController scrollController = ScrollController();

  Future<List<BookingData>>? future;
  List<BookingData> bookings = [];

  // Post job requests
  List<PostJobData> postJobRequests = [];
  int postJobPage = 1;
  bool isPostJobLastPage = false;

  // Map to store post job ID to PostJobData mapping for converted bookings
  Map<int, PostJobData> postJobMap = {};

  int page = 1;
  bool isLastPage = false;

  String selectedValue = BOOKING_TYPE_ALL;

  @override
  void initState() {
    super.initState();
    init();
    filterStore = FilterStore();

    afterBuildCreated(() {
      if (appStore.isLoggedIn) {
        setStatusBarColor(context.primaryColor);
      }
    });

    LiveStream().on(LIVESTREAM_UPDATE_BOOKING_LIST, (p0) {
      page = 1;
      postJobPage = 1;
      postJobRequests.clear();
      postJobMap.clear();
      appStore.setLoading(true);
      init();
      setState(() {});
    });
    cachedBookingStatusDropdown.validate().forEach((element) {
      element.isSelected = false;
    });
  }

  void init({String status = ''}) async {
    // Fetch regular bookings
    Future<List<BookingData>> bookingsFuture = getBookingList(
      page,
      serviceId: filterStore.serviceId.join(","),
      dateFrom: filterStore.startDate,
      dateTo: filterStore.endDate,
      providerId: filterStore.providerId.join(","),
      handymanId: filterStore.handymanId.join(","),
      bookingStatus: filterStore.bookingStatus.join(","),
      paymentStatus: filterStore.paymentStatus.join(","),
      paymentType: filterStore.paymentType.join(","),
      bookings: bookings,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );

    // Fetch published post job requests (status = "requested")
    Future<List<PostJobData>> postJobsFuture = getPostJobList(
      postJobPage,
      postJobList: postJobRequests,
      lastPageCallBack: (val) {
        isPostJobLastPage = val;
      },
    );

    future = Future.wait([bookingsFuture, postJobsFuture]).then((results) {
      List<BookingData> allBookings =
          List<BookingData>.from(results[0]);
      List<PostJobData> postJobs = results[1];

      // Clear post job map only on first page
      if (postJobPage == 1) {
        postJobMap.clear();
      }

      // Convert post job requests with status "requested" to BookingData format
      List<BookingData> convertedPostJobs = postJobs
          .where((postJob) => postJob.status == JOB_REQUEST_STATUS_REQUESTED)
          .map((postJob) {
        // Store mapping for later retrieval
        int postJobId = postJob.id?.toInt() ?? 0;
        postJobMap[postJobId] = postJob;
        return _convertPostJobToBooking(postJob);
      }).toList();

      // Combine and sort by date (most recent first)
      allBookings.addAll(convertedPostJobs);
      allBookings.sort((a, b) {
        String dateA = a.date ?? a.bookingDate ?? '';
        String dateB = b.date ?? b.bookingDate ?? '';
        return dateB.compareTo(dateA); // Descending order
      });

      return allBookings;
    });
  }

  // Helper function to convert PostJobData to BookingData
  BookingData _convertPostJobToBooking(PostJobData postJob) {
    // Default values for post jobs without assigned providers
    String defaultProviderImage = '$DOMAIN_URL/images/user/user.png';
    String defaultProviderName = language.lblWaitingForProviderApproval;

    // Extract provider information from service if available
    ServiceData? firstService =
        postJob.service?.isNotEmpty == true ? postJob.service!.first : null;

    // Only show provider info if a provider has actually been assigned (providerId is set)
    // The service's providerName/providerImage might be the user's own info if they created the service
    bool hasAssignedProvider =
        postJob.providerId != null && postJob.providerId! > 0;

    String? providerName;
    String? providerImage;
    int? providerId;

    if (hasAssignedProvider) {
      // Provider has been assigned, use provider info from service if available
      providerId = postJob.providerId?.toInt();

      // Check if providerName looks like an email (contains @) - if so, don't use it
      String? serviceProviderName = firstService?.providerName?.validate();
      bool isEmailFormat =
          serviceProviderName != null && serviceProviderName.contains('@');

      providerName = (serviceProviderName != null &&
              serviceProviderName.isNotEmpty &&
              !isEmailFormat)
          ? serviceProviderName
          : defaultProviderName;

      providerImage = firstService?.providerImage?.validate().isNotEmpty == true
          ? firstService!.providerImage
          : defaultProviderImage;
    } else {
      // No provider assigned yet, show placeholder
      providerId = null;
      providerName = defaultProviderName;
      providerImage = defaultProviderImage;
    }

    // Extract category name from service or post job category
    String? categoryName =
        firstService?.categoryName?.validate().isNotEmpty == true
            ? firstService!.categoryName
            : (postJob.category?.name?.validate().isNotEmpty == true
                ? postJob.category!.name
                : null);

    // Build service name with category if available
    String serviceName = firstService?.name ?? postJob.title ?? '';
    if (categoryName != null && categoryName.isNotEmpty) {
      serviceName = '$serviceName • $categoryName';
    }

    return BookingData(
      id: postJob.id?.toInt(),
      customerId: postJob.customerId?.toInt(),
      serviceId: firstService?.id?.toInt(),
      serviceName: serviceName,
      description: postJob.description,
      status: postJob.status,
      statusLabel: postJob.status?.toPostJobStatus() ?? 'Requested',
      date: postJob.createdAt,
      bookingDate: postJob.createdAt,
      totalAmount: postJob.jobPrice,
      amount: postJob.jobPrice,
      bookingType: BOOKING_TYPE_USER_POST_JOB,
      serviceAttachments: firstService?.attachments,
      handyman: <Handyman>[], // Empty list for post jobs since they don't have handyman assigned yet - must be non-null
      providerId: providerId,
      providerName: providerName,
      providerImage: providerImage,
      providerIsVerified:
          0, // Can be updated if provider verification status is available in API
      type: firstService?.type ??
          SERVICE_TYPE_FIXED, // Use service type if available
      paymentStatus: null, // Post jobs don't have payment status until booked
      paymentMethod: null,
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    filterStore.clearFilters();
    LiveStream().dispose(LIVESTREAM_UPDATE_BOOKING_LIST);
    //scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        language.booking,
        textColor: white,
        showBack: false,
        textSize: APP_BAR_TEXT_SIZE,
        elevation: 3.0,
        color: context.primaryColor,
        actions: [
          Observer(
            builder: (_) {
              int filterCount = filterStore.getActiveFilterCount();
              return Stack(
                children: [
                  IconButton(
                    icon: ic_filter.iconImage(color: white, size: 20),
                    onPressed: () async {
                      BookingFilterScreen(showHandymanFilter: true)
                          .launch(context)
                          .then((value) {
                        if (value != null) {
                          page = 1;
                          postJobPage = 1;
                          postJobRequests.clear();
                          postJobMap.clear();
                          appStore.setLoading(true);
                          init();
                          if (bookings.isNotEmpty) {
                            scrollController.animateTo(0,
                                duration: 1.seconds,
                                curve: Curves.easeOutQuart);
                          } else {
                            scrollController = ScrollController();
                            keyForList = UniqueKey();
                          }
                          setState(() {});
                        }
                      });
                    },
                  ),
                  if (filterCount > 0)
                    Positioned(
                      right: 7,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        child: FittedBox(
                          child: Text('$filterCount',
                              style: TextStyle(
                                  color: white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        decoration: boxDecorationDefault(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: EdgeInsets.zero,
        maxWidth: 800,
        child: Stack(
          children: [
            SnapHelperWidget<List<BookingData>>(
              initialData: cachedBookingList,
              future: future,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  imageWidget: ErrorStateWidget(),
                  retryText: language.reload,
                  onRetry: () {
                    page = 1;
                    postJobPage = 1;
                    postJobRequests.clear();
                    postJobMap.clear();
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  },
                );
              },
              loadingWidget: BookingShimmer(),
              onSuccess: (list) {
                return AnimatedListView(
                  key: keyForList,
                  controller: scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 60, top: 16),
                  itemCount: list.length,
                  shrinkWrap: true,
                  disposeScrollController: true,
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  slideConfiguration: SlideConfiguration(verticalOffset: 400),
                  emptyWidget: NoDataWidget(
                    title: language.lblNoBookingsFound,
                    subTitle: language.noBookingSubTitle,
                    imageWidget: EmptyStateWidget(),
                  ),
                  itemBuilder: (_, index) {
                    BookingData? data = list[index];

                    return GestureDetector(
                      onTap: () {
                        // Check if it's a post job request (published job, not yet a booking)
                        if (data.bookingType == BOOKING_TYPE_USER_POST_JOB &&
                            data.status == JOB_REQUEST_STATUS_REQUESTED) {
                          // Find the original post job using the map
                          PostJobData? postJob = postJobMap[data.id];
                          if (postJob != null) {
                            MyPostDetailScreen(
                              postRequestId: postJob.id.validate().toInt(),
                              callback: () {
                                page = 1;
                                postJobPage = 1;
                                postJobRequests.clear();
                                postJobMap.clear();
                                appStore.setLoading(true);
                                init();
                                setState(() {});
                              },
                            ).launch(context);
                          } else {
                            // Fallback: try to find in postJobRequests list
                            PostJobData? foundPostJob;
                            try {
                              foundPostJob = postJobRequests.firstWhere((p) =>
                                  p.id?.toInt() == data.id &&
                                  p.status == JOB_REQUEST_STATUS_REQUESTED);
                            } catch (e) {
                              foundPostJob = null;
                            }
                            if (foundPostJob != null) {
                              MyPostDetailScreen(
                                postRequestId:
                                    foundPostJob.id.validate().toInt(),
                                callback: () {
                                  page = 1;
                                  postJobPage = 1;
                                  postJobRequests.clear();
                                  postJobMap.clear();
                                  appStore.setLoading(true);
                                  init();
                                  setState(() {});
                                },
                              ).launch(context);
                            }
                          }
                        } else {
                          BookingDetailScreen(bookingId: data.id.validate())
                              .launch(context);
                        }
                      },
                      child: BookingItemComponent(bookingData: data),
                    );
                  },
                  onNextPage: () {
                    if (!isLastPage || !isPostJobLastPage) {
                      if (!isLastPage) {
                        page++;
                      }
                      if (!isPostJobLastPage) {
                        postJobPage++;
                      }
                      appStore.setLoading(true);

                      init(status: selectedValue);
                      setState(() {});
                    }
                  },
                  onSwipeRefresh: () async {
                    page = 1;
                    postJobPage = 1;
                    postJobRequests.clear();
                    postJobMap.clear();
                    appStore.setLoading(true);

                    init(status: selectedValue);
                    setState(() {});

                    return await 1.seconds.delay;
                  },
                );
              },
            ),
            Observer(
                builder: (_) => LoaderWidget().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}
