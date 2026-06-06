// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isFarmer => _currentUser?.role == UserRole.farmer;
  bool get isServiceProvider =>
      _currentUser?.role == UserRole.serviceProvider;

  AuthProvider() {
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      _auth!.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      debugPrint('Firebase Auth init skipped: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    } else {
      await _loadUserData(firebaseUser.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db?.collection('users').doc(uid).get();
      if (doc != null && doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    if (_auth == null) {
      return 'Firebase មិនទាន់បានកំណត់។ សូមកំណត់ firebase_options.dart';
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      await _auth!.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getKhmerError(e.code);
      _setLoading(false);
      return _errorMessage;
    } catch (e) {
      _errorMessage = 'មានបញ្ហាផ្ទៃក្នុង សូមព្យាយាមម្តងទៀត';
      _setLoading(false);
      return _errorMessage;
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? serviceType,
    String? idCard,
    String? address,
  }) async {
    if (_auth == null) {
      return 'Firebase មិនទាន់បានកំណត់។ សូមកំណត់ firebase_options.dart';
    }
    _setLoading(true);
    _errorMessage = null;
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

      final user = UserModel(
        uid: cred.user!.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        serviceType: serviceType,
        idCard: idCard,
        address: address,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _db?.collection('users').doc(cred.user!.uid).set(user.toMap());

      _currentUser = user;
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getKhmerError(e.code);
      _setLoading(false);
      return _errorMessage;
    } catch (e) {
      _errorMessage = 'មានបញ្ហាផ្ទៃក្នុង សូមព្យាយាមម្តងទៀត';
      _setLoading(false);
      return _errorMessage;
    }
  }

  Future<void> logout() async {
    await _auth?.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateLocation(double lat, double lng) async {
    if (_currentUser == null) return;
    await _db?.collection('users').doc(_currentUser!.uid).update({
      'latitude': lat,
      'longitude': lng,
    });
    _currentUser = _currentUser!.copyWith(latitude: lat, longitude: lng);
    notifyListeners();
  }

  Future<void> toggleActiveStatus(bool isActive) async {
    if (_currentUser == null) return;
    await _db?.collection('users').doc(_currentUser!.uid).update({
      'isActive': isActive,
    });
    _currentUser = _currentUser!.copyWith(isActive: isActive);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _getKhmerError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'អ៊ីមែលនេះមិនបានចុះឈ្មោះទេ';
      case 'wrong-password':
        return 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
      case 'email-already-in-use':
        return 'អ៊ីមែលនេះបានប្រើប្រាស់រួចហើយ';
      case 'invalid-email':
        return 'អ៊ីមែលមិនត្រឹមត្រូវ';
      case 'weak-password':
        return 'ពាក្យសម្ងាត់ត្រូវការយ៉ាងតិច ៦ តួអក្សរ';
      case 'network-request-failed':
        return 'មិនមានការភ្ជាប់អ៊ីនធឺណេត';
      case 'too-many-requests':
        return 'ព្យាយាមច្រើនពេក សូមព្យាយាមម្តងទៀតក្រោយ';
      case 'invalid-credential':
        return 'អ៊ីមែល ឬ ពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
      default:
        return 'មានកំហុសកើតឡើង ($code)';
    }
  }
}