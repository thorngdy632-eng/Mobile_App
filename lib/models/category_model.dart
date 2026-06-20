// lib/models/category_model.dart
import 'package:flutter/material.dart';

/// Lightweight model for a service category tile.
///
/// Used by [ServiceCategoriesRow] to render the horizontal-scroll
/// category strip on both the Farmer and Provider home screens.
class CategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
  });
}
