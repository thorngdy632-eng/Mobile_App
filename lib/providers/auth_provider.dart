// lib/providers/auth_provider.dart
import 'dart:convert'; // 🟢 ហៅប្រើសម្រាប់បំប្លែងរូបភាពទៅជា Base64 String
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Works perfectly on Web + Mobile
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // alias សម្រាប់កូដចាស់ៗហៅប្រើ
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── Auth state listener ───────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    await _fetchUserProfile(firebaseUser.uid);
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    notifyListeners();
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

  // ── Register ជំនាន់ថ្មី (លែងប្រើ Firebase Storage រួចរាល់ ១០០%) ───────────────

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? serviceType,
    String? idCard,
    String? address,
    XFile? idCardFrontFile, // ទទួលយក XFile ពី register_screen.dart
    XFile? idCardBackFile,
  }) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.1;
    _uploadStatus = 'កំពុងបង្កើតគណនី...';
    notifyListeners();

    try {
      // ── ជំហានទី ១៖ បង្កើតគណនីនៅលើ Firebase Auth ─────────────────────────────
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final String uid = credential.user!.uid;

      _uploadProgress = 0.3;
      _uploadStatus = 'កំពុងរៀបចំទិន្នន័យរូបភាព...';
      notifyListeners();

      // ── ជំហានទី ២៖ បំប្លែងរូបថតខាងមុខទៅជា Base64 String ────────────────────────
      String? frontImageBase64;
      if (idCardFrontFile != null) {
        _uploadStatus = 'កំពុងដំណើរការរូបថតខាងមុខ...';
        _uploadProgress = 0.45;
        notifyListeners();

        final Uint8List bytes = await idCardFrontFile.readAsBytes();
        frontImageBase64 = base64Encode(bytes); // បំប្លែងរូបទៅជាអក្សរ
      }

      // ── ជំហានទី ៣៖ បំប្លែងរូបថតខាងក្រោយទៅជា Base64 String ───────────────────────
      String? backImageBase64;
      if (idCardBackFile != null) {
        _uploadStatus = 'កំពុងដំណើរការរូបថតខាងក្រោយ...';
        _uploadProgress = 0.65;
        notifyListeners();

        final Uint8List bytes = await idCardBackFile.readAsBytes();
        backImageBase64 = base64Encode(bytes); // បំប្លែងរូបទៅជាអក្សរ
      }

      // ── ជំហានទី ៤៖ រក្សាទុកទិន្នន័យទាំងអស់ចូល Cloud Firestore ───────────────────
      _uploadStatus = 'កំពុងរក្សាទុកព័ត៌មាន...';
      _uploadProgress = 0.85;
      notifyListeners();

      final newUser = UserModel(
        uid: uid,
        fullName: fullName,
        email: email.trim(),
        phoneNumber: phoneNumber,
        role: role,
        address: address,
        serviceType: serviceType,
        idCard: idCard, // អាចរក្សាទុកតម្លៃ fallback បាន
        isActive: true,
        createdAt: DateTime.now(),
      );

      final userMap = newUser.toMap();
      
      // 🟢 បញ្ចូលខ្សែអក្សរ Base64 នៃរូបភាពទៅក្នុង Field ផ្ទាល់តែម្តង
      if (frontImageBase64 != null) userMap['idCardFrontUrl'] = frontImageBase64;
      if (backImageBase64 != null) userMap['idCardBackUrl'] = backImageBase64;
      
      // កំណត់ស្ថានភាពរង់ចាំការផ្ទៀងផ្ទាត់ (សម្រាប់តែអ្នកផ្តល់សេវាត្រាក់ទ័រ)
      if (role == UserRole.serviceProvider) userMap['idVerified'] = false;

      // រុញទិន្នន័យទាំងស្រុងទៅ Firestore (លែងគាំង លែងជាប់ Rules ញ៉ាំញ៉ៅ)
      await _db.collection('users').doc(uid).set(userMap);

      // ── បញ្ចប់ការចុះឈ្មោះដោយជោគជ័យ ─────────────────────────────────────────
      _currentUser = newUser;
      _uploadProgress = 1.0;
      _uploadStatus = 'ចុះឈ្មោះជោគជ័យ!';
      _isLoading = false;
      notifyListeners();

      // រង់ចាំបង្ហាញផ្ទាំង ១០០% បន្តិចសិន រួចសម្អាតផ្ទាំង Loading
      await Future.delayed(const Duration(milliseconds: 500));
      _uploadProgress = 0.0;
      _uploadStatus = '';
      notifyListeners();

      return null; // បញ្ជាក់ថាជោគជ័យ (គ្មាន Error)

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
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
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