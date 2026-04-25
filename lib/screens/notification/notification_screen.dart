import 'package:fiksOpp/component/base_scaffold_widget.dart';
import 'package:fiksOpp/component/loader_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/model/notification_model.dart';
import 'package:fiksOpp/network/rest_apis.dart';
import 'package:fiksOpp/screens/booking/booking_detail_screen.dart';
import 'package:fiksOpp/screens/chat/chat_list_screen.dart';
import 'package:fiksOpp/screens/chat/user_chat_screen.dart';
import 'package:fiksOpp/screens/jobRequest/my_post_detail_screen.dart';
import 'package:fiksOpp/screens/notification/components/notification_widget.dart';
import 'package:fiksOpp/screens/wallet/user_wallet_balance_screen.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<List<NotificationData>>? future;
  bool _notificationTapInProgress = false;

  List<NotificationData> _dedupeNotifications(List<NotificationData> input) {
    final seen = <String>{};
    final out = <NotificationData>[];
    for (final n in input) {
      final d = n.data;
      final key = [
        n.id.validate(),
        n.createdAt.validate(),
        d?.notificationType.validate() ?? '',
        d?.activityType.validate() ?? '',
        d?.message.validate() ?? '',
        (d?.bookingId ?? 0).toString(),
        (d?.postRequestId ?? 0).toString(),
      ].join('|');
      if (seen.add(key)) {
        out.add(n);
      }
    }
    return out;
  }
  bool _hasType(NotificationInnerData inner, String expected) {
    final nType = inner.notificationType.validate().toLowerCase();
    final type = inner.type.validate().toLowerCase();
    final activity = inner.activityType.validate().toLowerCase();
    final needle = expected.toLowerCase();
    return nType.contains(needle) ||
        type.contains(needle) ||
        activity.contains(needle);
  }

  bool _isChatNotification(NotificationInnerData inner) {
    final nType = inner.notificationType.validate().toLowerCase();
    final type = inner.type.validate().toLowerCase();
    final activity = inner.activityType.validate().toLowerCase();
    final checkBookingType = inner.checkBookingType.validate().toLowerCase();
    return nType.contains('chat_message') ||
        type.contains('chat') ||
        activity.contains('chat_message') ||
        checkBookingType == 'chat';
  }

  int _resolveBookingId(NotificationInnerData inner) {
    return inner.bookingId ?? inner.id ?? 0;
  }

  int _resolvePostRequestId(NotificationInnerData inner) {
    return inner.postRequestId ?? inner.jobId ?? inner.id ?? 0;
  }

  Future<void> _openPostRequest(
    BuildContext context,
    int postRequestId,
    NotificationData data,
  ) async {
    if (postRequestId <= 0) {
      log(
          '[NotificationTap] invalid postRequestId for notificationId=${data.id}');
      toast(language.postJobDataNotFound);
      return;
    }

    log('[NotificationTap] opening post detail postRequestId=$postRequestId '
        'notificationId=${data.id}');
    try {
      final response =
          await getPostJobDetail({PostJob.postRequestId: postRequestId});
      if (response.postRequestDetail != null) {
        await MyPostDetailScreen(
          postJobData: response.postRequestDetail!,
          postRequestId: postRequestId,
          callback: () {},
        ).launch(context);
      } else {
        toast(language.postJobDataNotFound);
      }
    } catch (e) {
      log('[NotificationTap] post detail error: $e');
      toast(e.toString());
    }
  }

  Future<void> _openChatFromNotification(
    BuildContext context,
    NotificationInnerData inner,
    NotificationData data,
  ) async {
    final senderId = inner.senderId;
    final receiverId = inner.receiverId;
    final currentUserId = appStore.userId;
    final targetId =
        (senderId != null && senderId != currentUserId) ? senderId : receiverId;

    if (targetId == null || targetId <= 0) {
      log('[NotificationTap] chat target id missing for notificationId=${data.id}');
      await ChatListScreen().launch(context);
      return;
    }

    final receiverUser = await userService.getUserByIdNull(targetId);
    if (receiverUser != null) {
      log('[NotificationTap] opening direct chat with userId=$targetId');
      await UserChatScreen(receiverUser: receiverUser).launch(context);
    } else {
      log('[NotificationTap] chat user not found, opening chat list userId=$targetId');
      await ChatListScreen().launch(context);
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init({Map? req}) async {
    future = getNotification(request: req);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblNotification,
      actions: [
        IconButton(
          icon: Icon(Icons.clear_all_rounded, color: Colors.white),
          onPressed: () async {
            appStore.setLoading(true);

            init(req: {NotificationKey.type: MARK_AS_READ});

            setState(() {});
          },
        ),
      ],
      child: SnapHelperWidget<List<NotificationData>>(
        future: future,
        initialData: cachedNotificationList,
        loadingWidget: LoaderWidget(),
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              init();
              setState(() {});
            },
          );
        },
        onSuccess: (list) {
          final visibleList = _dedupeNotifications(list);
          return AnimatedListView(
            shrinkWrap: true,
            itemCount: visibleList.length,
            slideConfiguration: sliderConfigurationGlobal,
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            emptyWidget: NoDataWidget(
              title: language.noNotifications,
              subTitle: language.noNotificationsSubTitle,
              imageWidget: EmptyStateWidget(),
            ),
            onSwipeRefresh: () {
              appStore.setLoading(true);

              init();
              setState(() {});
              return 2.seconds.delay;
            },
            itemBuilder: (context, index) {
              NotificationData data = visibleList[index];

              return GestureDetector(
                 onTap: () async {
                  if (_notificationTapInProgress) {
                    log('[NotificationTap] ignored duplicate tap');
                    return;
                  }
                  _notificationTapInProgress = true;

                  final inner = data.data;
                  log(
                      '[NotificationTap] start notificationId=${data.id} hasInner=${inner != null}');
                  if (inner == null) {
                    log('[NotificationTap] no payload for notificationId=${data.id}');
                    toast('No action available for this notification');
                    _notificationTapInProgress = false;
                    return;
                  }

                  try {
                    final bookingId = _resolveBookingId(inner);
                    final postRequestId = _resolvePostRequestId(inner);
                    final typeSummary =
                        'type=${inner.type} activity=${inner.activityType} notificationType=${inner.notificationType}';
                    log('[NotificationTap] parsed bookingId=$bookingId '
                        'postRequestId=$postRequestId $typeSummary');

                    if (_hasType(inner, WALLET)) {
                      log('[NotificationTap] branch=wallet');
                      if (appConfigurationStore.onlinePaymentStatus) {
                        await UserWalletBalanceScreen().launch(context);
                      }
                    } else if (_isChatNotification(inner)) {
                      log('[NotificationTap] branch=chat');
                      await _openChatFromNotification(context, inner, data);
                    } else if (_hasType(inner, BOOKING) ||
                        _hasType(inner, PAYMENT_MESSAGE_STATUS)) {
                      log('[NotificationTap] branch=booking');
                      if (bookingId > 0) {
                        await BookingDetailScreen(bookingId: bookingId)
                            .launch(context);
                      } else {
                        toast('Booking data not found');
                      }
                    } else if (_hasType(inner, PROVIDER_SEND_BID)) {
                      log('[NotificationTap] branch=provider_send_bid');
                      await _openPostRequest(context, postRequestId, data);
                    } else {
                      log('[NotificationTap] branch=fallback');
                      if (postRequestId > 0) {
                        await _openPostRequest(context, postRequestId, data);
                      } else if (bookingId > 0) {
                        await BookingDetailScreen(bookingId: bookingId)
                            .launch(context);
                      } else {
                        toast('No action available for this notification');
                      }
                    }
                  } finally {
                    _notificationTapInProgress = false;
                    log('[NotificationTap] end notificationId=${data.id}');
                  }
                },
                child: NotificationWidget(data: data),
              );
            },
          );
        },
      ),
    );
  }
}
