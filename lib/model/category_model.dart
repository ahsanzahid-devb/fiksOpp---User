import 'package:booking_system_flutter/model/pagination_model.dart';

class CategoryResponse {
  List<CategoryData>? categoryList;
  Pagination? pagination;

  CategoryResponse({this.categoryList, this.pagination});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryList: json['data'] != null
          ? (json['data'] as List).map((i) => CategoryData.fromJson(i)).toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (categoryList != null) {
      data['data'] = categoryList!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class CategoryData {
  int? id;
  String? name;
  String? description;
  int? status;
  int? isFeatured;
  String? color;
  int? categoryId;
  String? categoryName;
  String? categoryImage;
  String? categoryExtension;
  int? services;
  String? deletedAt;
  bool isSelected;

  CategoryData({
    this.id,
    this.name,
    this.description,
    this.status,
    this.isFeatured,
    this.color,
    this.categoryId,
    this.categoryName,
    this.categoryImage,
    this.categoryExtension,
    this.services,
    this.deletedAt,
    this.isSelected = false,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      isFeatured: json['is_featured'],
      color: json['color'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryImage: json['category_image'],
      categoryExtension: json['category_extension'],
      services: json['services'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['status'] = status;
    data['is_featured'] = isFeatured;
    data['color'] = color;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['category_image'] = categoryImage;
    data['category_extension'] = categoryExtension;
    data['services'] = services;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
