// lib/models/equipment_item.dart

enum EquipmentBadge { none, hot, new_ }

class EquipmentItem {
  final String name;
  final String price;
  final String location;
  final double rating;
  final String imageAsset;
  final EquipmentBadge badge;

  const EquipmentItem({
    required this.name,
    required this.price,
    required this.location,
    required this.rating,
    required this.imageAsset,
    this.badge = EquipmentBadge.none,
  });
}
