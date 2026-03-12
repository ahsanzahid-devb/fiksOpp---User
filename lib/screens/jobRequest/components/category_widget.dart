import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class CategoryWidget extends StatelessWidget {
  final dynamic categoryName;
  final dynamic subCategoryName;
  final Color? color;
  final int? size; // 👈 Changed from double? → int? to match text style

  const CategoryWidget({
    Key? key,
    this.categoryName,
    this.subCategoryName,
    this.color,
    this.size = 14, // 👈 default int value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String categoryText = categoryName?.toString().validate() ?? '';
    String subCategoryText = subCategoryName?.toString().validate() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryText.isNotEmpty)
          Text(
            '${language.categoryLabel}: $categoryText',
            style: secondaryTextStyle(size: size, color: color),
          ),
        if (subCategoryText.isNotEmpty)
          Text(
            '${language.subCategoryLabel}: $subCategoryText',
            style: secondaryTextStyle(size: size, color: color),
          ),
      ],
    );
  }
}
