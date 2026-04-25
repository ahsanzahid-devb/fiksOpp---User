class NotificationListResponse {
  List<NotificationData>? notificationData;
  int? allUnreadCount;

  NotificationListResponse({this.notificationData, this.allUnreadCount});

  NotificationListResponse.fromJson(Map<String, dynamic> json) {
    if (json['notification_data'] != null) {
      notificationData = [];
      json['notification_data'].forEach((v) {
        notificationData!.add(new NotificationData.fromJson(v));
      });
    }
    allUnreadCount = json['all_unread_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.notificationData != null) {
      data['notification_data'] = this.notificationData!.map((v) => v.toJson()).toList();
    }
    data['all_unread_count'] = this.allUnreadCount;
    return data;
  }
}

class NotificationData {
  String? id;
  String? readAt;
  String? createdAt;
  String? profileImage;
  NotificationInnerData? data;

  NotificationData({this.id, this.readAt, this.createdAt, this.data});

  NotificationData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    readAt = json['read_at']?.toString();
    createdAt = json['created_at']?.toString();
    profileImage = json['profile_image']?.toString();
    if (json['data'] is Map<String, dynamic>) {
      data = NotificationInnerData.fromJson(json['data']);
    } else if (_looksLikeNotificationPayload(json)) {
      // Some APIs return notification fields at root instead of under `data`.
      data = NotificationInnerData.fromJson(json);
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['read_at'] = this.readAt;
    data['created_at'] = this.createdAt;
    data['profile_image'] = this.profileImage;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class NotificationInnerData {
  int? id;
  String? type;
  String? activityType;
  String? subject;
  String? message;
  String? notificationType;
  String? checkBookingType;
  int? jobId;
  int? bookingId;
  int? postRequestId;
  int? senderId;
  int? receiverId;

  NotificationInnerData({
    this.id,
    this.type,
    this.activityType,
    this.checkBookingType,
    this.subject,
    this.message,
    this.notificationType,
    this.jobId,
    this.bookingId,
    this.postRequestId,
    this.senderId,
    this.receiverId,
  });

  NotificationInnerData.fromJson(Map<String, dynamic> json) {
    final bidData = json['bid_data'];
    final bidDataMap =
        bidData is Map ? Map<String, dynamic>.from(bidData) : null;
    id = _asInt(json['id']);
    type = json['type']?.toString();
    activityType = json['activity_type']?.toString();
    subject = json['subject']?.toString();
    message = json['message']?.toString();
    notificationType =
        (json['notification-type'] ?? json['notification_type'])?.toString();
    checkBookingType = json['check_booking_type']?.toString();
    jobId = _asInt(json['job_id'] ?? json['job_request_id']);
    bookingId = _asInt(json['booking_id'] ?? json['booking']?['id']);
    postRequestId = _asInt(
      json['post_request_id'] ??
          json['job_request_id'] ??
          json['job_id'] ??
          bidDataMap?['post_request_id'] ??
          json['booking']?['post_request_id'],
    );
    senderId = _asInt(json['sender_id']);
    receiverId = _asInt(json['receiver_id']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['activity_type'] = this.activityType;
    data['subject'] = this.subject;
    data['message'] = this.message;
    data['notification-type'] = this.notificationType;
    data['check_booking_type'] = this.checkBookingType;
    data['job_id'] = this.jobId;
    data['booking_id'] = this.bookingId;
    data['post_request_id'] = this.postRequestId;
    data['sender_id'] = this.senderId;
    data['receiver_id'] = this.receiverId;
    return data;
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

bool _looksLikeNotificationPayload(Map<String, dynamic> json) {
  return json.containsKey('notification-type') ||
      json.containsKey('notification_type') ||
      json.containsKey('activity_type') ||
      json.containsKey('booking_id') ||
      json.containsKey('post_request_id') ||
      json.containsKey('job_id') ||
      json.containsKey('type');
}