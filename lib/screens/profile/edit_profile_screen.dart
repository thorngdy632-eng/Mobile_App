// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  Uint8List? _imageBytes;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final source = await _showSourceSheet();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
    });
  }

  Future<ImageSource?> _showSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourceSheet(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final Map<String, dynamic> updates = {
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      };

      // If a new profile image was picked, encode as Base64 and save
      if (_imageBytes != null) {
        updates['profileImageUrl'] = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Refresh local user model
      final updatedUser = user.copyWith(
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        profileImageUrl: _imageBytes != null
            ? base64Encode(_imageBytes!)
            : user.profileImageUrl,
      );

      // Re-fetch from Firestore to update provider state properly
      // We directly update the provider's internal user via a workaround:
      // Since AuthProvider exposes the stream-based _fetchUserProfile,
      // we just pop and the parent will re-read the updated Firestore data.

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានរក្សាទុកដោយជោគជ័យ ✓'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មានបញ្ហា: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('កែប្រែព័ត៌មាន'),
        backgroundColor: _roleColor(user?.role),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'រក្សាទុក',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile image picker ──────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor:
                            _roleColor(user?.role).withOpacity(0.15),
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : _existingImage(user?.profileImageUrl),
                        child: (_imageBytes == null &&
                                (user?.profileImageUrl == null ||
                                    user!.profileImageUrl!.isEmpty))
                            ? Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _roleColor(user?.role)),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _roleColor(user?.role),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ចុចដើម្បីផ្លាស់ប្ដូររូបភាព',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),

              const SizedBox(height: 28),

              // ── Role badge ──────────────────────────────────────────────
              if (user != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _roleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _roleColor(user.role).withOpacity(0.3)),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _roleColor(user.role)),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Fields ──────────────────────────────────────────────────
              _buildCard(children: [
                _buildField(
                  controller: _nameCtrl,
                  label: 'ឈ្មោះពេញ',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'សូមបញ្ចូលឈ្មោះ'
                          : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'លេខទូរស័ព្ទ',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
                    }
                    if (v.trim().length < 9) {
                      return 'លេខទូរស័ព្ទត្រូវការយ៉ាងហោចណាស់ ៩ ខ្ទង់';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _addressCtrl,
                  label: 'អាសយដ្ឋាន',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'សូមបញ្ចូលអាសយដ្ឋាន'
                          : null,
                ),
              ]),

              const SizedBox(height: 16),

              // ── Read-only info ──────────────────────────────────────────
              _buildCard(children: [
                _buildReadOnly(
                    label: 'អ៊ីមែល',
                    value: user?.email ?? '',
                    icon: Icons.email_outlined),
                if (user?.serviceType != null) ...[
                  const Divider(height: 24, color: Color(0xFFF0F0F0)),
                  _buildReadOnly(
                      label: 'ប្រភេទសេវា',
                      value: user!.serviceType!,
                      icon: Icons.work_outline),
                ],
              ]),

              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor(user?.role),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'រក្សាទុកការផ្លាស់ប្ដូរ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppTheme.bgLight,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
      ),
    );
  }

  Widget _buildReadOnly({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  ImageProvider? _existingImage(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(base64));
    } catch (_) {
      return null;
    }
  }

  Color _roleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.adminBlue;
      case UserRole.serviceProvider:
        return AppTheme.providerOrange;
      default:
        return AppTheme.farmerGreen;
    }
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('ជ្រើសរើសប្រភព',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined,
                color: AppTheme.adminBlue),
            title: const Text('ថតរូបភ្លាម'),
            onTap: () =>
                Navigator.pop(context, ImageSource.camera),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppTheme.farmerGreen),
            title: const Text('ជ្រើសពីរូបថត'),
            onTap: () =>
                Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}