// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kUserRole = 'userRole';
  static const _kCachedRole = 'cached_user_role';
  static const _kCachedUid = 'cached_user_uid';
  static const _kCachedName = 'cached_user_name';

  // ── Reserved admin account ───────────────────────────────────────────────
  static const String _adminEmail = 'admin@gmail.com';
  static const String _adminPassword = 'admin@123';

  static bool _isReservedAdminCredential(String email, String password) {
    return email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword;
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // On cold start, fetch profile immediately from cached SharedPreferences
    // so home screens have _currentUser populated before Firebase resolves
    _initFromCache();
  }

  /// Called on cold start — reads cached uid from SharedPreferences and
  /// fetches the full user profile from Firestore in the background.
  /// Sets _isInitializing = false so the UI isn't stuck waiting.
  ///
  /// On cold start, Firebase Auth may not have restored its session yet,
  /// so Firestore queries fail with permission-denied. This method waits
  /// for Firebase Auth to restore before attempting the Firestore fetch.
  Future<void> _initFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kCachedUid);
    if (uid == null || _currentUser != null) return;

    // ── Wait for Firebase Auth to restore its session ──
    // On cold start, _auth.currentUser may be null for a few hundred ms
    // while Firebase validates the persisted token. If we hit Firestore
    // before that, request.auth is null and the query is rejected.
    if (_auth.currentUser == null) {
      try {
        await _auth.authStateChanges().firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Timeout or stream ended — proceed with SharedPreferences fallback
        debugPrint('⚠️ AuthProvider: Firebase Auth did not restore in time, using cache only');
      }
    }

    // First try Firestore (Firebase Auth session should now be active)
    try {
      final doc = await _db.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
        await _cacheProfile(_currentUser!);
        _isInitializing = false;
        notifyListeners();
        debugPrint('✅ AuthProvider: profile loaded from Firestore via cache uid=$uid');
        return;
      }
    } catch (_) {}

    // Fallback — build from SharedPreferences data
    final roleName = prefs.getString(_kCachedRole);
    final name = prefs.getString(_kCachedName);
    if (roleName != null) {
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.farmer,
      );
      _currentUser = UserModel(
        uid: uid,
        fullName: name ?? 'អ្នកប្រើប្រាស់',
        email: _auth.currentUser?.email ?? '',
        phoneNumber: _auth.currentUser?.phoneNumber ?? '',
        role: role,
        createdAt: DateTime.now(),
      );
      _isInitializing = false;
      notifyListeners();
      debugPrint('✅ AuthProvider: profile restored from SharedPreferences cache');
    }
  }

  // ── Auth state listener ───────────────────────────────────────────────────
  //
  // On cold start, Firebase Auth's authStateChanges() may emit null briefly
  // (token validation delay) BEFORE emitting the real User. This is a
  // well-documented initialization artifact on Web/iOS.
  //
  // If we wipe _currentUser on that transient null, all Firestore queries
  // fail with permission-denied because request.auth becomes null.
  //
  // Two guards prevent the transient wipe:
  //   Guard 1 — _currentUser already populated from SharedPreferences cache
  //   Guard 2 — SharedPreferences isLoggedIn flag is true (session active)
  //
  // The logout() method clears the cache BEFORE calling signOut(), so
  // when authStateChanges fires null during logout, both guards fail
  // and the wipe proceeds normally.

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      // ── Guard 1: profile already loaded from cache → don't wipe ──
      if (_currentUser != null) {
        debugPrint('⏳ AuthProvider: ignoring null emission (profile already loaded)');
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // ── Guard 2: SharedPreferences has an active session ──
      // _initFromCache() is probably still running its Firestore fetch
      // (or waiting for Firebase Auth to restore). Don't wipe — the
      // profile will arrive shortly.
      final sessionCached = await isSessionCached();
      if (sessionCached) {
        debugPrint('⏳ AuthProvider: ignoring null emission (session cached, waiting for init)');
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // ── No cache, no profile → genuine logout or first-time user ──
      // Both guards failed: cache was cleared by logout() or user never logged in.
      debugPrint('🔄 AuthProvider: null auth state (no cached session)');
      _currentUser = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    // ── Firebase Auth confirmed a real user ──
    if (_currentUser != null) {
      // Profile already loaded from cache — refresh in background (fire-and-forget)
      _isInitializing = false;
      notifyListeners();
      _fetchUserProfile(firebaseUser.uid);
      return;
    }

    // No profile yet — fetch from Firestore
    await _fetchUserProfile(firebaseUser.uid);
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
        await _cacheProfile(_currentUser!);
      } else {
        final fbUser = _auth.currentUser;
        _currentUser = UserModel(
          uid: uid,
          fullName: fbUser?.displayName ?? 'អ្នកប្រើប្រាស់',
          email: fbUser?.email ?? '',
          phoneNumber: fbUser?.phoneNumber ?? '',
          role: UserRole.farmer,
          createdAt: DateTime.now(),
        );
        debugPrint('⚠️ Firestore doc missing for $uid — created fallback UserModel');
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      final cached = await _loadCachedProfile();
      if (cached != null) {
        _currentUser = cached;
        debugPrint('✅ Restored profile from cache: ${cached.role.name}');
      }
    }
    notifyListeners();
  }

  // ── SharedPreferences cache helpers ──────────────────────────────────────

  Future<void> _cacheProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUid, user.uid);
    await prefs.setString(_kCachedRole, user.role.name);
    await prefs.setString(_kCachedName, user.fullName);
  }

  /// Saves explicit isLoggedIn + userRole keys (Web/iOS persistence)
  Future<void> _saveLoginSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setString(_kUserRole, user.role.name);
    await _cacheProfile(user);
  }

  Future<UserModel?> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kCachedUid);
    final roleName = prefs.getString(_kCachedRole);
    final name = prefs.getString(_kCachedName);
    if (uid == null || roleName == null) return null;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.farmer,
    );
    return UserModel(
      uid: uid,
      fullName: name ?? 'អ្នកប្រើប្រាស់',
      email: '',
      phoneNumber: '',
      role: role,
      createdAt: DateTime.now(),
    );
  }

  static Future<UserRole?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_kCachedRole);
    if (roleName == null) return null;
    return UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.farmer,
    );
  }

  static Future<String?> getCachedUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCachedUid);
  }

  /// Reads explicit login flag from SharedPreferences
  static Future<bool> isSessionCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  /// Reads cached user role string from SharedPreferences
  static Future<String?> getCachedRoleString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserRole);
  }

  /// Clears ALL cached auth data (called on logout)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserRole);
    await prefs.remove(_kCachedUid);
    await prefs.remove(_kCachedRole);
    await prefs.remove(_kCachedName);
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _fetchUserProfile(credential.user!.uid);

      // Explicitly save login session for Web/iOS persistence
      if (_currentUser != null) {
        await _saveLoginSession(_currentUser!);
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _mapAuthError(e.code);
      notifyListeners();
      return _error;
    } catch (e) {
      _isLoading = false;
      _error = 'មានបញ្ហា: $e';
      notifyListeners();
      return _error;
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? serviceType,
    String? idCard,
    String? address,
    XFile? idCardFrontFile,
    XFile? idCardBackFile,
  }) async {
    UserRole effectiveRole = role;
    if (_isReservedAdminCredential(email, password)) {
      effectiveRole = UserRole.admin;
    } else if (role == UserRole.admin) {
      effectiveRole = UserRole.farmer;
    }

    _isLoading = true;
    _error = null;
    _uploadProgress = 0.1;
    _uploadStatus = 'កំពុងបង្កើតគណនី...';
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final String uid = credential.user!.uid;

      _uploadProgress = 0.3;
      _uploadStatus = 'កំពុងរៀបចំទិន្នន័យរូបភាព...';
      notifyListeners();

      String? frontImageBase64;
      if (idCardFrontFile != null) {
        _uploadStatus = 'កំពុងដំណើរការរូបថតខាងមុខ...';
        _uploadProgress = 0.45;
        notifyListeners();
        final Uint8List bytes = await idCardFrontFile.readAsBytes();
        frontImageBase64 = base64Encode(bytes);
      }

      String? backImageBase64;
      if (idCardBackFile != null) {
        _uploadStatus = 'កំពុងដំណើរការរូបថតខាងក្រោយ...';
        _uploadProgress = 0.65;
        notifyListeners();
        final Uint8List bytes = await idCardBackFile.readAsBytes();
        backImageBase64 = base64Encode(bytes);
      }

      _uploadStatus = 'កំពុងរក្សាទុកព័ត៌មាន...';
      _uploadProgress = 0.85;
      notifyListeners();

      final newUser = UserModel(
        uid: uid,
        fullName: fullName,
        email: email.trim(),
        phoneNumber: phoneNumber,
        role: effectiveRole,
        address: address,
        serviceType: effectiveRole == UserRole.serviceProvider ? serviceType : null,
        idCard: idCard,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final userMap = newUser.toMap();
      if (frontImageBase64 != null) userMap['idCardFrontUrl'] = frontImageBase64;
      if (backImageBase64 != null) userMap['idCardBackUrl'] = backImageBase64;
      if (effectiveRole == UserRole.serviceProvider) userMap['idVerified'] = false;

      await _db.collection('users').doc(uid).set(userMap);

      _currentUser = newUser;

      // Explicitly save login session for Web/iOS persistence
      await _saveLoginSession(newUser);

      _uploadProgress = 1.0;
      _uploadStatus = 'ចុះឈ្មោះជោគជ័យ!';
      _isLoading = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      _uploadProgress = 0.0;
      _uploadStatus = '';
      notifyListeners();

      return null;

    } on FirebaseAuthException catch (e) {
      _resetLoadingState();
      _error = _mapAuthError(e.code);
      notifyListeners();
      return _error;
    } catch (e) {
      _resetLoadingState();
      _error = 'មានបញ្ហា: $e';
      notifyListeners();
      return _error;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    // 1. Clear SharedPreferences FIRST so _onAuthStateChanged(null) — triggered
    //    by signOut() below — doesn't hit Guard 2 (isSessionCached) and proceed
    //    to wipe normally.
    await clearCache();
    _currentUser = null;
    notifyListeners();
    // 2. Now sign out from Firebase Auth (triggers authStateChanges → null).
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // ── Refresh profile from Firestore ────────────────────────────────────────

  Future<void> refreshProfile() async {
    // Prefer Firebase Auth's live UID; fall back to SharedPreferences cache.
    // If neither exists, there's nothing to refresh.
    final uid = _auth.currentUser?.uid ?? await getCachedUid();
    if (uid != null) {
      await _fetchUserProfile(uid);
    } else {
      debugPrint('⚠️ refreshProfile: no UID available (Firebase null, no cache)');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _resetLoadingState() {
    _isLoading = false;
    _uploadProgress = 0.0;
    _uploadStatus = '';
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'រកមិនឃើញអ្នកប្រើប្រាស់';
      case 'wrong-password':
        return 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
      case 'invalid-credential':
        return 'អ៊ីមែល ឬ ពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
      case 'email-already-in-use':
        return 'អ៊ីមែលនេះត្រូវបានប្រើប្រាស់រួចហើយ';
      case 'weak-password':
        return 'ពាក្យសម្ងាត់ខ្សោយពេក';
      case 'invalid-email':
        return 'អ៊ីមែលមិនត្រឹមត្រូវ';
      case 'network-request-failed':
        return 'មានបញ្ហាបណ្ដាញ — សូមព្យាយាមម្ដងទៀត';
      case 'too-many-requests':
        return 'ព្យាយាមច្រើនដងពេក — សូមរង់ចាំ';
      default:
        return 'មានបញ្ហា ($code)';
    }
  }
}
