// lib/screens/auth/register_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';
import 'shared_auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  UserRole _role = UserRole.farmer;
  String? _serviceType;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  int _step = 0;

  // ID card images — now required for ALL roles
  XFile? _idFront;
  XFile? _idBack;
  Uint8List? _idFrontBytes;
  Uint8List? _idBackBytes;
  final _picker = ImagePicker();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final List<String> _serviceTypes = [
    'ម៉ាស៊ីនស្ទូច', 'ម៉ាស៊ីនដាំ', 'ម៉ាស៊ីនបូម',
    'រថយន្តដឹក', 'គ្រឿងសសៃ', 'សសៃបូម', 'ម៉ាស៊ីនកៀរ', 'សេវាផ្សេងៗ',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.trim().isEmpty ||
          _addressCtrl.text.trim().isEmpty) {
        _showError('សូមបំពេញព័ត៌មានផ្ទាល់ខ្លួនទាំងអស់');
        return false;
      }
      if (_phoneCtrl.text.trim().length < 9) {
        _showError('លេខទូរស័ព្ទមិនត្រឹមត្រូវ');
        return false;
      }
      return true;
    }

    if (_step == 1) {
      // Service type required for providers only
      if (_role == UserRole.serviceProvider && _serviceType == null) {
        _showError('សូមជ្រើសរើសប្រភេទសេវាកម្ម');
        return false;
      }
      // ID card required for ALL roles
      if (_idFront == null) {
        _showError('សូមបន្ថែមរូបថតខាងមុខអត្តសញ្ញាណប័ណ្ណ');
        return false;
      }
      if (_idBack == null) {
        _showError('សូមបន្ថែមរូបថតខាងក្រោយអត្តសញ្ញាណប័ណ្ណ');
        return false;
      }
      return true;
    }

    if (_step == 2) {
      if (_emailCtrl.text.trim().isEmpty ||
          !_emailCtrl.text.contains('@')) {
        _showError('អ៊ីមែលមិនត្រឹមត្រូវ');
        return false;
      }
      if (_passwordCtrl.text.length < 6) {
        _showError('ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួ');
        return false;
      }
      if (_passwordCtrl.text != _confirmCtrl.text) {
        _showError('ពាក្យសម្ងាត់មិនដូចគ្នា');
        return false;
      }
      return true;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(
                        fontFamily: 'KhmerOSBattambang'))),
          ],
        ),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (!_validateStep()) return;
    if (_step < 2) {
      _fadeCtrl.reset();
      setState(() => _step++);
      _fadeCtrl.forward();
    } else {
      _handleRegister();
    }
  }

  void _onBack() {
    if (_step > 0) {
      _fadeCtrl.reset();
      setState(() => _step--);
      _fadeCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phoneNumber: _phoneCtrl.text.trim(),
      role: _role,
      address: _addressCtrl.text.trim(),
      serviceType:
          _role == UserRole.serviceProvider ? _serviceType : null,
      idCardFrontFile: _idFront,
      idCardBackFile: _idBack,
    );
    if (!mounted) return;
    if (err == null) {
      _navigateByRole(_role);
    } else {
      _showError(err);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    HapticFeedback.selectionClick();
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      if (isFront) {
        _idFront = picked;
        _idFrontBytes = bytes;
      } else {
        _idBack = picked;
        _idBackBytes = bytes;
      }
    });
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ImageSourceSheet(),
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
          // ── Full-screen rice paddy background ───────────────────────────
          Image.asset(
            'assets/images/background_login_form.jfif',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.70),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Centered registration card ──────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: const AssetImage(
                              'assets/images/background_login_form.jfif'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.45),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top bar
                          _buildTopBar(),

                          // Step indicator
                          _buildStepIndicator(),

                          // Form content
                          FadeTransition(
                            opacity: _fade,
                            child: Form(
                              key: _formKey,
                              child: _buildCurrentStep(),
                            ),
                          ),

                          // Action bar
                          _buildActionBar(auth),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (auth.isLoading) _UploadOverlay(auth: auth),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: _onBack,
          ),
          const Text(
            'តោះជួល!',
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            'ចុះឈ្មោះថ្មី',
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['ព័ត៌មាន', 'តួនាទី', 'សម្ងាត់'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final completed = (i ~/ 2) < _step;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: completed
                        ? [
                            const Color(0xFF66BB6A),
                            const Color(0xFF43A047)
                          ]
                        : [Colors.white12, Colors.white12],
                  ),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx == _step;
          final isDone = stepIdx < _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 36 : 32,
            height: isActive ? 36 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? const Color(0xFF43A047)
                  : isActive
                      ? const Color(0xFF66BB6A)
                      : Colors.white10,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF66BB6A)
                    : isDone
                        ? const Color(0xFF43A047)
                        : Colors.white24,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF66BB6A)
                            .withOpacity(0.4),
                        blurRadius: 12,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 16)
                  : Text(
                      '${stepIdx + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : Colors.white38,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ── STEP 1: Personal info ──────────────────────────────────────────────────

  Widget _buildStep1() {
    return _StepCard(
      title: 'ព័ត៌មានផ្ទាល់ខ្លួន',
      subtitle: 'បំពេញព័ត៌មានដែលត្រូវការ',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          GlassField(
            controller: _nameCtrl,
            hint: 'ឈ្មោះ នាមត្រកូល',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'សូមបញ្ចូលឈ្មោះ' : null,
          ),
          const SizedBox(height: 16),
          GlassField(
            controller: _phoneCtrl,
            hint: '012 345 678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
              if (v.length < 9) {
                return 'លេខទូរស័ព្ទត្រូវមានយ៉ាងហោចណាស់ ៩ ខ្ទង់';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassField(
            controller: _addressCtrl,
            hint: 'ភូមិ ឃុំ ស្រុក ខេត្ត',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'សូមបញ្ចូលអាសយដ្ឋាន' : null,
          ),
        ],
      ),
    );
  }

  // ── STEP 2: Role + ID card upload (ALL roles) ──────────────────────────────

  Widget _buildStep2() {
    return Column(
      children: [
        _StepCard(
          title: 'ជ្រើសរើសតួនាទី',
          subtitle: 'តួនាទីក្នុងប្រព័ន្ធ Dorne',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              _buildRoleCard(
                role: UserRole.farmer,
                emoji: '👨‍🌾',
                title: 'កសិករ',
                description: 'ស្វែងរក និងទំនាក់ទំនងអ្នកផ្តល់សេវា',
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              _buildRoleCard(
                role: UserRole.serviceProvider,
                emoji: '🚜',
                title: 'អ្នកផ្តល់សេវា',
                description: 'ផ្សព្វផ្សាយសេវា និងទទួលការជួល',
                color: const Color(0xFFE65100),
              ),
              const SizedBox(height: 10),
              _buildRoleCard(
                role: UserRole.admin,
                emoji: '👨‍💼',
                title: 'អ្នកគ្រប់គ្រង',
                description: 'គ្រប់គ្រងប្រព័ន្ធ សេវា និងអ្នកប្រើប្រាស់',
                color: const Color(0xFF1565C0),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Service type — only for service providers
        if (_role == UserRole.serviceProvider)
          _StepCard(
            title: 'ប្រភេទសេវាកម្ម',
            subtitle: 'ជ្រើសរើសសេវាដែលអ្នកផ្តល់',
            icon: Icons.work_outline,
            accentColor: const Color(0xFFE65100),
            child: _buildServiceTypeDropdown(),
          ),

        if (_role == UserRole.serviceProvider)
          const SizedBox(height: 16),

        // ID card upload — required for ALL roles
        _StepCard(
          title: 'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណប័ណ្ណ',
          subtitle: 'ត្រូវការទាំងពីរខាង · Required for all roles',
          icon: Icons.credit_card_outlined,
          accentColor: const Color(0xFF1565C0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _IdCardUploadTile(
                      label: 'រូបថតខាងមុខ',
                      sublabel: 'Front Side',
                      emoji: '🪪',
                      image: _idFront,
                      imageBytes: _idFrontBytes,
                      onTap: () => _pickImage(true),
                      onDelete: () => setState(() {
                        _idFront = null;
                        _idFrontBytes = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IdCardUploadTile(
                      label: 'រូបថតខាងក្រោយ',
                      sublabel: 'Back Side',
                      emoji: '🪪',
                      image: _idBack,
                      imageBytes: _idBackBytes,
                      onTap: () => _pickImage(false),
                      onDelete: () => setState(() {
                        _idBack = null;
                        _idBackBytes = null;
                      }),
                      isBack: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildIdCardStatus(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _serviceType,
      dropdownColor: const Color(0xFF1B3A20),
      style: const TextStyle(
          fontFamily: 'KhmerOSBattambang',
          color: Colors.white,
          fontSize: 14),
      decoration: InputDecoration(
        hintText: 'ជ្រើសរើសប្រភេទសេវា',
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
            fontFamily: 'KhmerOSBattambang'),
        prefixIcon: const Icon(Icons.category_outlined,
            color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFFFFB74D), width: 1.8),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down,
          color: Colors.white54, size: 20),
      items: _serviceTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _serviceType = v),
    );
  }

  Widget _buildIdCardStatus() {
    final frontOk = _idFront != null;
    final backOk = _idBack != null;
    final allOk = frontOk && backOk;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: allOk
            ? const Color(0xFF2E7D32).withOpacity(0.2)
            : const Color(0xFF1565C0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: allOk
              ? const Color(0xFF66BB6A).withOpacity(0.5)
              : const Color(0xFF90CAF9).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allOk ? Icons.verified_outlined : Icons.info_outline,
            size: 16,
            color: allOk
                ? const Color(0xFF66BB6A)
                : const Color(0xFF90CAF9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              allOk
                  ? 'រូបថតទាំងពីរខាងត្រូវបានបន្ថែម ✓'
                  : !frontOk && !backOk
                      ? 'សូមបន្ថែមរូបថតអត្តសញ្ញាណប័ណ្ណ ទាំងពីរខាង'
                      : !frontOk
                          ? 'នៅខ្វះរូបថតខាងមុខ'
                          : 'នៅខ្វះរូបថតខាងក្រោយ',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                fontSize: 12,
                color: allOk
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFF90CAF9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _role = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? color
                          : Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(Icons.check_circle,
                      color: color, size: 22,
                      key: const ValueKey('checked'))
                  : Icon(Icons.circle_outlined,
                      color: Colors.white24, size: 22,
                      key: const ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 3: Security ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    return _StepCard(
      title: 'ព័ត៌មានសម្ងាត់',
      subtitle: 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួ',
      icon: Icons.lock_outline_rounded,
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          GlassField(
            controller: _passwordCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
              if (v.length < 6) return 'យ៉ាងហោចណាស់ ៦ តួ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassField(
            controller: _confirmCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'សូមបញ្ជាក់ពាក្យសម្ងាត់';
              }
              if (v != _passwordCtrl.text) {
                return 'ពាក្យសម្ងាត់មិនដូចគ្នា';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'សង្ខេបការចុះឈ្មោះ',
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow('👤 ឈ្មោះ', _nameCtrl.text.trim()),
          _summaryRow('📱 ទូរស័ព្ទ', _phoneCtrl.text.trim()),
          _summaryRow(
            '🎭 តួនាទី',
            _role == UserRole.farmer
                ? 'កសិករ'
                : _role == UserRole.serviceProvider
                    ? 'អ្នកផ្តល់សេវា'
                    : 'អ្នកគ្រប់គ្រង',
          ),
          if (_role == UserRole.serviceProvider)
            _summaryRow('🔧 សេវាកម្ម', _serviceType ?? '-'),
          _summaryRow(
            '🪪 អត្តសញ្ញាណប័ណ្ណ',
            (_idFront != null && _idBack != null)
                ? 'បានបន្ថែម ✓'
                : 'មិនទាន់',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                  fontFamily: 'KhmerOSBattambang',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildActionBar(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          if (_step > 0) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GreenButton(
              label: _step < 2 ? 'បន្ត →' : 'ចុះឈ្មោះ',
              loading: auth.isLoading,
              onPressed: _onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ID Card Upload Tile ───────────────────────────────────────────────────────

class _IdCardUploadTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final String emoji;
  final XFile? image;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isBack;

  const _IdCardUploadTile({
    required this.label,
    required this.sublabel,
    required this.emoji,
    required this.image,
    this.imageBytes,
    required this.onTap,
    required this.onDelete,
    this.isBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    return GestureDetector(
      onTap: hasImage ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 150,
        decoration: BoxDecoration(
          color: hasImage
              ? Colors.transparent
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF66BB6A).withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: hasImage ? 1.8 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child:
              hasImage ? _buildPreview() : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          imageBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          top: 6,
          right: 6,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBack
                  ? Icons.flip_to_back_outlined
                  : Icons.flip_to_front_outlined,
              color: const Color(0xFF90CAF9),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF90CAF9).withOpacity(0.4)),
            ),
            child: const Text(
              '+ បន្ថែម',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                fontSize: 10,
                color: Color(0xFF90CAF9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 4.0;
    const radius = Radius.circular(15);
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), radius);
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    double dist = 0;
    while (dist < metric.length) {
      canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
      dist += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Image Source Sheet ────────────────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ជ្រើសរើសប្រភព',
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'ថតរូបភ្លាម',
            sublabel: 'Camera',
            color: const Color(0xFF29B6F6),
            onTap: () =>
                Navigator.pop(context, ImageSource.camera),
          ),
          const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Colors.white10),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'ជ្រើសពីឯកសាររូបថត',
            sublabel: 'Gallery',
            color: const Color(0xFF66BB6A),
            onTap: () =>
                Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'បោះបង់',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                color: Colors.white.withOpacity(0.45),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}

// ── Upload Progress Overlay ───────────────────────────────────────────────────

class _UploadOverlay extends StatelessWidget {
  final AuthProvider auth;
  const _UploadOverlay({required this.auth});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A20),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFF1B5E20)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.upload_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  auth.uploadStatus.isNotEmpty
                      ? auth.uploadStatus
                      : 'កំពុងដំណើរការ...',
                  style: const TextStyle(
                    fontFamily: 'KhmerOSBattambang',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: auth.uploadProgress > 0
                        ? auth.uploadProgress
                        : null,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF66BB6A)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                if (auth.uploadProgress > 0)
                  Text(
                    '${(auth.uploadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step Card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Color accentColor;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.accentColor = const Color(0xFF66BB6A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}