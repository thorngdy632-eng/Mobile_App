import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    // 1) FAST PATH — synchronous read from Firebase local cache (instant on Android)
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      _navigated = true;
      _goToHome(fbUser.uid);
      return;
    }

    // 2) SLOW PATH — Firebase Auth hasn't restored session yet, wait for the stream
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted || _navigated) return;

      if (user != null) {
        _navigated = true;
        _goToHome(user.uid);
      } else {
        // Stream emitted null = truly not logged in
        _navigated = true;
        _goToLogin();
      }
    });
  }

  Future<void> _goToHome(String uid) async {
    final cachedRole = await AuthProvider.getCachedRole();

    if (!mounted) return;

    Widget home;
    if (cachedRole != null) {
      home = _routeByRole(cachedRole);
    } else {
      home = await _fetchRoleFromFirestore(uid);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (_) => false,
    );
  }

  Future<Widget> _fetchRoleFromFirestore(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final role = UserRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => UserRole.farmer,
        );
        return _routeByRole(role);
      }
    } catch (_) {}
    return _routeByRole(UserRole.farmer);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _routeByRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.farmer:
        return const FarmerHome();
      case UserRole.serviceProvider:
        return const ProviderHome();
    }
  }

  @override
  Widget build(BuildContext context) => const _BootSplash();
}

// ── Themed splash ───────────────────────────────────────────────────────────

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F0E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF66BB6A),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20),
            const Text(
              'កំពុងផ្ទុក...',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
