// lib/widgets/category_item.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// A single rounded-square category tile with an icon and label.
///
/// Designed for use inside a horizontal-scroll row. Tap triggers [onTap].
class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;
  final double size;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: category.backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  category.icon,
                  color: category.iconColor,
                  size: size * 0.45,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
