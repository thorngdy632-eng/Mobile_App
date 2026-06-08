// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Still waiting for Firebase Auth to resolve the persisted session
    if (auth.isInitializing) {
      return const _BootSplash();
    }

    // Session found → route by role
    if (auth.currentUser != null) {
      return _routeByRole(auth.currentUser!.role);
    }

    // No session → login
    return const LoginScreen();
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
}

// ── Themed splash shown while Firebase resolves the auth token ───────────────

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1F0E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon
            FlutterLogo(size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF66BB6A),
              strokeWidth: 2.5,
            ),
            SizedBox(height: 20),
            Text(
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
