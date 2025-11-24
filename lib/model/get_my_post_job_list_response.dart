import 'package:booking_system_flutter/model/pagination_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';

class GetPostJobResponse {
  Pagination? pagination;
  List<PostJobData>? myPostJobData;

  GetPostJobResponse({this.pagination, this.myPostJobData});

  GetPostJobResponse.fromJson(dynamic json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;

    if (json['data'] != null) {
      myPostJobData = [];
      json['data'].forEach((v) {
        myPostJobData?.add(PostJobData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pagination != null) map['pagination'] = pagination?.toJson();
    if (myPostJobData != null) {
      map['data'] = myPostJobData?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Category {
  int? id;
  String? name;

  Category({this.id, this.name});

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class SubCategory {
  int? id;
  String? name;

  SubCategory({this.id, this.name});

  SubCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class PostJobData {
  num? id;
  String? title;
  String? description;
  String? reason;

  /// 🔹 Updated: Use String to support both numeric and textual price/date input
  String? price;

  num? jobPrice;
  num? providerId;
  num? customerId;
  String? status;
  bool? canBid;
  String? createdAt;
  List<ServiceData>? service;

  Category? category;
  SubCategory? subCategory;

  PostJobData({
    this.id,
    this.title,
    this.description,
    this.reason,
    this.price,
    this.jobPrice,
    this.providerId,
    this.customerId,
    this.status,
    this.canBid,
    this.service,
    this.createdAt,
    this.category,
    this.subCategory,
  });

  PostJobData.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    reason = json['reason'];

    // 🔹 Convert price safely to String
    price = json['price'] != null ? json['price'].toString() : null;

    jobPrice = json['job_price'];
    providerId = json['provider_id'];
    customerId = json['customer_id'];
    status = json['status'];
    canBid = json['can_bid'];
    createdAt = json['created_at'];

    category =
        json['category'] != null ? Category.fromJson(json['category']) : null;
    subCategory = json['sub_category'] != null
        ? SubCategory.fromJson(json['sub_category'])
        : null;

    if (json['service'] != null) {
      service = [];
      json['service'].forEach((v) {
        service?.add(ServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['reason'] = reason;
    map['price'] = price; // 🔹 Already a string
    map['job_price'] = jobPrice;
    map['provider_id'] = providerId;
    map['customer_id'] = customerId;
    map['status'] = status;
    map['can_bid'] = canBid;
    map['created_at'] = createdAt;

    if (category != null) map['category'] = category!.toJson();
    if (subCategory != null) map['sub_category'] = subCategory!.toJson();
    if (service != null)
      map['service'] = service?.map((v) => v.toJson()).toList();
    return map;
  }
}

class BidderData {
  int? id;
  int? postRequestId;
  int? providerId;

  /// Keep numeric price for bidder (optional)
  num? price;

  String? duration;
  UserData? provider;

  BidderData({
    this.id,
    this.postRequestId,
    this.providerId,
    this.price,
    this.duration,
    this.provider,
  });

  BidderData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postRequestId = json['post_request_id'];
    providerId = json['provider_id'];
    price = json['price'];
    duration = json['duration'];
    provider =
        json['provider'] != null ? UserData.fromJson(json['provider']) : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['post_request_id'] = postRequestId;
    map['provider_id'] = providerId;
    map['price'] = price;
    map['duration'] = duration;
    if (provider != null) map['provider'] = provider!.toJson();
    return map;
  }
}
