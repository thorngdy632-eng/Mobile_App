// lib/models/service_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── The 5 services shown on the Farmer home screen ───────────────────────────
//
// Each service provider (UserModel.serviceType) should be registered with one
// of these `id` values so that AppProvider can match a farmer's request to the
// correct group of providers.

class ServiceTypes {
  static const String plowing = 'plowing'; // គោយន្ដ
  static const String harvesting = 'harvesting'; // ម៉ាស៊ីនច្រូត
  static const String droneSpray = 'drone_spray'; // ការងារ
  static const String transport = 'transport'; // ត្រាក់ទ័រ
  static const String irrigation = 'irrigation'; // ត្រូន

  /// Ordered list used to build the 5-button grid on the Farmer home screen.
  static const List<Map<String, dynamic>> all = [
    {
      'id': plowing,
      'label': 'គោយន្ដ',
      'subtitle': 'សេវាដោយគោយន្ដ',
      'icon': Icons.agriculture,
      'color': Color(0xFF2E7D32),
    },
    {
      'id': harvesting,
      'label': 'ម៉ាស៊ីនច្រូត',
      'subtitle': 'សេវាច្រូតដោយម៉ាស៊ីនច្រូត',
      'icon': Icons.grass,
      'color': Color(0xFFF9A825),
    },
    {
      'id': droneSpray,
      'label': 'ការងារ',
      'subtitle': 'សេវាការងារកសិកម្ម',
      'icon': Icons.flight,
      'color': Color(0xFF1565C0),
    },
    {
      'id': transport,
      'label': 'ត្រាក់ទ័រ',
      'subtitle': 'សេវាត្រាក់ទ័រ',
      'icon': Icons.local_shipping,
      'color': Color(0xFF6D4C41),
    },
    {
      'id': irrigation,
      'label': 'ត្រូន',
      'subtitle': 'សេវាដ្រូន',
      'icon': Icons.water_drop,
      'color': Color(0xFF00897B),
    },
  ];

  static Map<String, dynamic> infoOf(String id) => all.firstWhere(
        (e) => e['id'] == id,
        orElse: () => all.first,
      );

  static String labelOf(String id) => infoOf(id)['label'] as String;
}

// ─── Land area unit ────────────────────────────────────────────────────────────

enum LandUnit { rai, hectare }

extension LandUnitX on LandUnit {
  String get label => this == LandUnit.rai ? 'រ៉ៃ (Rai)' : 'ហេកតា (Hectare)';

  String get value => this == LandUnit.rai ? 'rai' : 'hectare';

  static LandUnit fromString(String v) =>
      v == 'rai' ? LandUnit.rai : LandUnit.hectare;
}

// ─── ServiceRequest ─────────────────────────────────────────────────────────────
//
// Created by a Farmer when they drop a pin on the FlutterMap/OSM panel and
// submit the request form. Read in real time by matching Service Providers
// (filtered by `serviceType`) so they can accept / decline and contact the
// farmer.

class ServiceRequest {
  final String id;
  final String farmerUid;
  final String farmerName;
  final String placeOfBirth;

  /// Where the farmer dropped the pin (their current / job location).
  final double latitude;
  final double longitude;

  /// Human-readable description of the dropped location
  /// (e.g. reverse-geocoded address, or "Lat, Lng" fallback).
  final String currentAddress;

  /// One of [ServiceTypes] ids.
  final String serviceType;

  final double landArea;
  final String landUnit; // 'rai' | 'hectare'

  /// How much the farmer is willing to pay for this job (USD).
  final double offerPrice;

  /// pending | accepted | declined | completed | cancelled
  final String status;

  final String? providerUid;
  final String? providerName;

  /// UIDs of providers who were shown this request and declined it. A
  /// decline only removes the request from *that* provider's queue — every
  /// other matching provider must still see it and be able to accept it.
  final List<String> declinedBy;

  final DateTime createdAt;
  final String? notes;

  const ServiceRequest({
    required this.id,
    required this.farmerUid,
    required this.farmerName,
    required this.placeOfBirth,
    required this.latitude,
    required this.longitude,
    required this.currentAddress,
    required this.serviceType,
    required this.landArea,
    required this.landUnit,
    required this.offerPrice,
    required this.status,
    this.providerUid,
    this.providerName,
    this.declinedBy = const [],
    required this.createdAt,
    this.notes,
  });

  factory ServiceRequest.fromMap(Map<String, dynamic> map, String id) {
    return ServiceRequest(
      id: id,
      farmerUid: map['farmerUid'] ?? '',
      farmerName: map['farmerName'] ?? 'កសិករ',
      placeOfBirth: map['placeOfBirth'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      currentAddress: map['currentAddress'] ?? '',
      serviceType: map['serviceType'] ?? ServiceTypes.plowing,
      landArea: (map['landArea'] as num?)?.toDouble() ?? 0.0,
      landUnit: map['landUnit'] ?? 'hectare',
      offerPrice: (map['offerPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      providerUid: map['providerUid'],
      providerName: map['providerName'],
      declinedBy: List<String>.from(map['declinedBy'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerUid': farmerUid,
        'farmerName': farmerName,
        'placeOfBirth': placeOfBirth,
        'latitude': latitude,
        'longitude': longitude,
        'currentAddress': currentAddress,
        'serviceType': serviceType,
        'landArea': landArea,
        'landUnit': landUnit,
        'offerPrice': offerPrice,
        'status': status,
        'providerUid': providerUid,
        'providerName': providerName,
        'declinedBy': declinedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'notes': notes,
      };

  ServiceRequest copyWith({
    String? status,
    String? providerUid,
    String? providerName,
    List<String>? declinedBy,
  }) {
    return ServiceRequest(
      id: id,
      farmerUid: farmerUid,
      farmerName: farmerName,
      placeOfBirth: placeOfBirth,
      latitude: latitude,
      longitude: longitude,
      currentAddress: currentAddress,
      serviceType: serviceType,
      landArea: landArea,
      landUnit: landUnit,
      offerPrice: offerPrice,
      status: status ?? this.status,
      providerUid: providerUid ?? this.providerUid,
      providerName: providerName ?? this.providerName,
      declinedBy: declinedBy ?? this.declinedBy,
      createdAt: createdAt,
      notes: notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'ទទួលយល់ព្រម';
      case 'declined':
        return 'បានបដិសេធ';
      case 'completed':
        return 'បានបញ្ចប់';
      case 'cancelled':
        return 'បានបោះបង់';
      default:
        return 'កំពុងរង់ចាំចម្លើយ';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'declined':
        return const Color(0xFFD32F2F);
      case 'completed':
        return const Color(0xFF1565C0);
      case 'cancelled':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFF9A825);
    }
  }

  String get landLabel {
    final unit = LandUnitX.fromString(landUnit).label;
    return '${landArea.toStringAsFixed(landArea.truncateToDouble() == landArea ? 0 : 2)} $unit';
  }
}