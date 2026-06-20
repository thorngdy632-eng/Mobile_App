import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('AuthWrapper — connectionState: ${snapshot.connectionState}');
        debugPrint('AuthWrapper — hasData: ${snapshot.hasData}');
        debugPrint('AuthWrapper — currentUser: ${snapshot.data?.uid}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootSplash();
        }

        if (snapshot.data != null) {
          return _ProfileLoader(uid: snapshot.data!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}

// ── Fetches the Firestore user profile, then routes by role ─────────────────

class _ProfileLoader extends StatefulWidget {
  final String uid;
  const _ProfileLoader({required this.uid});

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  int _retries = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    while (_retries < _maxRetries && mounted) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!mounted) return;

      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final role = UserRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => UserRole.farmer,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => _routeByRole(role)),
          (_) => false,
        );
        return;
      }

      _retries++;
      if (_retries < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * _retries));
      }
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
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
  Widget build(BuildContext context) {
    return const _BootSplash();
  }
}

// ── Themed splash shown while Firebase resolves the auth token ───────────────

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
