import 'package:fiksOpp/model/pagination_model.dart';
import 'package:fiksOpp/model/service_data_model.dart';
import 'package:fiksOpp/model/user_data_model.dart';
import 'package:nb_utils/nb_utils.dart';

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

  /// From `post_request_detail` when API returns them (same values sent on save-post-job).
  num? latitude;
  num? longitude;
  String? address;
  int? cityId;

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
    this.latitude,
    this.longitude,
    this.address,
    this.cityId,
  });

  /// Mirrors provider bidding rules: need coords, address, city, or service-level location data.
  bool get hasUsableLocationForProviders {
    if (address.validate().isNotEmpty) return true;
    if (cityId != null && cityId! > 0) return true;
    if (latitude != null && longitude != null) return true;
    for (final s in service.validate()) {
      if (s.hasUsableLocationForProviders) return true;
    }
    return false;
  }

  String? get resolvedLocationLabel {
    if (address.validate().isNotEmpty) return address;
    if (latitude != null && longitude != null) {
      return '${latitude!.toString()}, ${longitude!.toString()}';
    }
    return null;
  }

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

    latitude = json['latitude'] is num
        ? json['latitude'] as num?
        : num.tryParse(json['latitude']?.toString() ?? '');
    longitude = json['longitude'] is num
        ? json['longitude'] as num?
        : num.tryParse(json['longitude']?.toString() ?? '');
    address = json['address']?.toString();
    cityId = json['city_id'] is int
        ? json['city_id'] as int?
        : int.tryParse(json['city_id']?.toString() ?? '');

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
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['address'] = address;
    map['city_id'] = cityId;
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
