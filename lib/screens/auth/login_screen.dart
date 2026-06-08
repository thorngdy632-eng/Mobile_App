// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'register_screen.dart';
import 'shared_auth_widgets.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// Design language: Refined agricultural authority — deep forest greens,
// clean geometry, confident Khmer typography, subtle depth through layering.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;

  // Animation controllers
  late final AnimationController _heroCtrl;
  late final AnimationController _formCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _heroFade =
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
            begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));

    _formFade =
        CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(
            begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      _heroCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300),
          () => _formCtrl.forward());
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _formCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _navigateByRole(UserRole role) {
    Widget dest;
    switch (role) {
      case UserRole.admin:
        dest = const AdminDashboard();
        break;
      case UserRole.farmer:
        dest = const FarmerHome();
        break;
      case UserRole.serviceProvider:
        dest = const ProviderHome();
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      _fadeRoute(dest),
      (route) => false,
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final err =
        await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    if (err == null) {
      _navigateByRole(auth.currentUser!.role);
    } else {
      _showErrorBar(err);
    }
  }

  void _showErrorBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F0E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen rice paddy background image ─────────────────────
          Image.asset(
            'assets/images/background_login_form.jfif',
            fit: BoxFit.cover,
          ),

          // ── Dark gradient overlay for legibility ────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.50),
                  Colors.black.withOpacity(0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Centered content ────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero (logo + title)
                      FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: _heroSlide,
                          child: _buildHero(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form card
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: _buildFormCard(auth),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────────
          if (auth.isLoading) LoadingOverlay(),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'តោះជួល',
          style: TextStyle(
            fontFamily: 'KhmerOSBattambang',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ── Form card ─────────────────────────────────────────────────────────────

  Widget _buildFormCard(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ចូលក្នុងគណនីរបស់អ្នក',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'សូមបញ្ចូលអ៊ីមែល និងពាក្យសម្ងាត់',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                fontSize: 13,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 28),
            _buildLabel('អ៊ីមែល'),
            const SizedBox(height: 8),
            GlassField(
              controller: _emailCtrl,
              hint: 'example@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';
                if (!v.contains('@')) return 'អ៊ីមែលមិនត្រឹមត្រូវ';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('ពាក្យសម្ងាត់'),
            const SizedBox(height: 8),
            GlassField(
              controller: _passwordCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'សូមបញ្ចូលពាក្យសម្ងាត់';
                }
                if (v.length < 6) return 'យ៉ាងហោចណាស់ ៦ តួ';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) =>
                        setState(() => _rememberMe = v ?? false),
                    checkColor: const Color(0xFF0A1F0E),
                    fillColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF66BB6A);
                      }
                      return Colors.white24;
                    }),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(
                        color: Colors.white38, width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ចងចាំគណនី',
                  style: TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            GreenButton(
              label: 'ចូល',
              loading: auth.isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.15),
                        height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'ឬ',
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.15),
                        height: 1)),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  _fadeRoute(const RegisterScreen()),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'មិនទាន់មានគណនី? ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55)),
                      ),
                      const TextSpan(
                        text: 'ចុះឈ្មោះ →',
                        style: TextStyle(
                          color: Color(0xFF81C784),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildRoleBadges(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      );

  Widget _buildRoleBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'តួនាទីក្នុងប្រព័ន្ធ',
          style: TextStyle(
            fontFamily: 'KhmerOSBattambang',
            fontSize: 12,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _rolePill('👨‍💼', 'អ្នកគ្រប់គ្រង', const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            _rolePill('👨‍🌾', 'កសិករ', const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            _rolePill('🚜', 'អ្នកផ្តល់សេវា', const Color(0xFFE65100)),
          ],
        ),
      ],
    );
  }

  Widget _rolePill(String emoji, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      );
}
