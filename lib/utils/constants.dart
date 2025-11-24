import 'package:flutter/material.dart';

const defaultRadius = 8.0;
const defaultPadding = 16.0;
const defaultSpacing = 8.0;

final dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(defaultRadius)));

BorderRadius radiusOnly({
  double topLeft = 0.0,
  double topRight = 0.0,
  double bottomLeft = 0.0,
  double bottomRight = 0.0,
}) {
  return BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomLeft: Radius.circular(bottomLeft),
    bottomRight: Radius.circular(bottomRight),
  );
}
