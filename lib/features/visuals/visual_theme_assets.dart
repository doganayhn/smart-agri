import 'package:flutter/material.dart';

class VisualThemeAssets {
  static const int valley = 1;
  static const int hill = 2;
  static const int greenhouse = 3;
  static const int rowCrops = 4;
  static const int orchard = 5;
  static const int circular = 6;

  /// Returns the base illustration widget for a given visual ID.
  /// For MVP, these are represented by styled Icon/Container compositions.
  /// In a full production build, these would return Image.asset('path/to/svg').
  static Widget getBaseIllustration(int visualId) {
    IconData icon;
    switch (visualId) {
      case valley: icon = Icons.landscape; break;
      case hill: icon = Icons.terrain; break;
      case greenhouse: icon = Icons.home_work; break;
      case rowCrops: icon = Icons.view_headline; break;
      case orchard: icon = Icons.forest; break;
      case circular: icon = Icons.radio_button_checked; break;
      default: icon = Icons.eco;
    }

    return Icon(
      icon,
      size: 180,
      color: Colors.green[800],
    );
  }
}
