import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, farmer, serviceProvider }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? serviceType; // for service providers
  final String? idCard;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.coverImageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.serviceType,
    this.idCard,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.farmer,
      ),
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address'],
      serviceType: map['serviceType'],
      idCard: map['idCard'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'serviceType': serviceType,
      'idCard': idCard,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    String? coverImageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? serviceType,
    String? idCard,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      serviceType: serviceType ?? this.serviceType,
      idCard: idCard ?? this.idCard,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'អ្នកគ្រប់គ្រង';
      case UserRole.farmer:
        return 'កសិករ';
      case UserRole.serviceProvider:
        return 'អ្នកផ្តល់សេវា';
    }
  }
}