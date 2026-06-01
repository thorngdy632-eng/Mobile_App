// lib/models/backhaul_load.dart
import 'package:flutter/material.dart';

/// Represents a backhaul cargo opportunity
class BackhaulLoad {
  final int id;
  final String cargo;         // e.g. 'ជី' (fertilizer)
  final IconData icon;
  final String from;
  final String to;
  final String weight;
  final String price;
  final Color color;          // icon background color

  const BackhaulLoad({
    required this.id,
    required this.cargo,
    required this.icon,
    required this.from,
    required this.to,
    required this.weight,
    required this.price,
    required this.color,
  });
}
