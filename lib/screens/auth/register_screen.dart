import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../farmer/farmer_home.dart';
import '../provider/provider_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _idCardController = TextEditingController(); // Added for Service Provider ID Card

  UserRole _selectedRole = UserRole.farmer;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentStep = 0;

  final List<String> _serviceTypes = [
    'ម៉ាស៊ីនស្ទូច',
    'ម៉ាស៊ីនដាំ',
    'ម៉ាស៊ីនបូម',
    'រថយន្តដឹក',
    'គ្រឿងសសៃ',
    'សសៃបូម',
    'ម៉ាស៊ីនកៀរ',
    'សេវាផ្សេងៗ',
  ];
  String? _selectedServiceType;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _serviceTypeController.dispose();
    _idCardController.dispose(); // Added to prevent memory leaks
    super.dispose();
  }

  void _navigateByRole(UserRole role) {
    Widget destination;
    switch (role) {
      case UserRole.admin:
        destination = const AdminDashboard();
        break;
      case UserRole.farmer:
        destination = const FarmerHome();
        break;
      case UserRole.serviceProvider:
        destination = const ProviderHome();
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim(),
      role: _selectedRole,
      serviceType: _selectedRole == UserRole.serviceProvider
          ? _selectedServiceType
          : null,
      idCard: _selectedRole == UserRole.serviceProvider
          ? _idCardController.text.trim()
          : null, // Submits ID card info only for Service Provider
      address: _addressController.text.trim(),
    );

    if (error == null && mounted) {
      _navigateByRole(_selectedRole);
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('ចុះឈ្មោះថ្មី'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _handleRegister();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          minimumSize: const Size(0, 48),
                        ),
                        child: auth.isLoading && _currentStep == 2
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'ចុះឈ្មោះ' : 'បន្ទាប់',
                                style: const TextStyle(
                                  fontFamily: 'KhmerOSBattambang',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        child: Text(
                          _currentStep == 0 ? 'ត្រឡប់' : 'ថយក្រោយ',
                          style: const TextStyle(
                            fontFamily: 'KhmerOSBattambang',
                            fontSize: 15,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text(
        'ព័ត៌មានផ្ទាល់ខ្លួន',
        style: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w600,
        ),
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'ឈ្មោះពេញ',
            hint: 'ឈ្មោះ នាមត្រកូល',
            icon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលឈ្មោះ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'លេខទូរស័ព្ទ',
            hint: '012 345 678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
              if (v.length < 9) return 'លេខទូរស័ព្ទត្រូវមានយ៉ាងហោចណាស់ ៩ ខ្ទង់';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'អាសយដ្ឋាន',
            hint: 'ភូមិ ឃុំ ស្រុក ខេត្ត',
            icon: Icons.location_on_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលអាសយដ្ឋាន';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text(
        'ជ្រើសរើសតួនាទី',
        style: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w600,
        ),
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'តួនាទីរបស់អ្នកក្នុងប្រព័ន្ធ',
            style: TextStyle(
              fontFamily: 'KhmerOSBattambang',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoleCard(
            role: UserRole.farmer,
            emoji: '👨‍🌾',
            title: 'កសិករ',
            description: 'ស្វែងរក និងទំនាក់ទំនងអ្នកផ្តល់សេវាកសិកម្ម',
            color: AppTheme.farmerGreen,
          ),
          const SizedBox(height: 10),
          _buildRoleCard(
            role: UserRole.serviceProvider,
            emoji: '🚜',
            title: 'អ្នកផ្តល់សេវា',
            description: 'ផ្សព្វផ្សាយសេវានិងទទួលការជួល',
            color: AppTheme.providerOrange,
          ),
          const SizedBox(height: 10),
          _buildRoleCard(
            role: UserRole.admin,
            emoji: '👨‍💼',
            title: 'អ្នកគ្រប់គ្រង',
            description: 'គ្រប់គ្រងប្រព័ន្ធ សេវា និងអ្នកប្រើប្រាស់',
            color: AppTheme.adminBlue,
          ),
          if (_selectedRole == UserRole.serviceProvider) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'ព័ត៌មានសេវាកម្ម និងអត្តសញ្ញាណប័ណ្ណ',
              style: TextStyle(
                fontFamily: 'KhmerOSBattambang',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.providerOrange,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryGreen),
                labelText: 'ប្រភេទសេវា',
                hintText: 'ជ្រើសរើសប្រភេទសេវា',
              ),
              items: _serviceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(fontFamily: 'KhmerOSBattambang'),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedServiceType = v),
              style: const TextStyle(
                fontFamily: 'KhmerOSBattambang',
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              validator: (v) {
                if (_selectedRole == UserRole.serviceProvider && v == null) {
                  return 'សូមជ្រើសរើសប្រភេទសេវា';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _idCardController,
              label: 'លេខអត្តសញ្ញាណប័ណ្ណ (ID Card)',
              hint: 'បញ្ចូលលេខអត្តសញ្ញាណប័ណ្ណសញ្ជាតិខ្មែរ',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (_selectedRole == UserRole.serviceProvider) {
                  if (v == null || v.isEmpty) {
                    return 'សូមបញ្ចូលលេខអត្តសញ្ញាណប័ណ្ណរបស់អ្នក';
                  }
                  if (v.length < 9) {
                    return 'លេខអត្តសញ្ញាណប័ណ្ណមិនត្រឹមត្រូវទេ';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text(
        'ព័ត៌មានសម្ងាត់',
        style: TextStyle(
          fontFamily: 'KhmerOSBattambang',
          fontWeight: FontWeight.w600,
        ),
      ),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'អ៊ីមែល',
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
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'ពាក្យសម្ងាត់',
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppTheme.primaryGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            style: const TextStyle(fontFamily: 'KhmerOSBattambang'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
              if (v.length < 6) return 'យ៉ាងហោចណាស់ ៦ តួ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'បញ្ជាក់ពាក្យសម្ងាត់',
              hintText: '••••••••',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppTheme.primaryGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            style: const TextStyle(fontFamily: 'KhmerOSBattambang'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'សូមបញ្ជាក់ពាក្យសម្ងាត់';
              if (v != _passwordController.text) {
                return 'ពាក្យសម្ងាត់មិនដូចគ្នា';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'KhmerOSBattambang',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'KhmerOSBattambang'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
      ),
      validator: validator,
    );
  }
}