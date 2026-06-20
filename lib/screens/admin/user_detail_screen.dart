// lib/screens/admin/user_detail_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../models/service_request.dart' show ServiceTypes;
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: _roleColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (me != null && me.uid != user.uid)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 22),
                  tooltip: 'លុបអ្នកប្រើប្រាស់',
                  onPressed: () => _confirmAndDelete(context),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_roleColor, _roleColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _profileImage,
                        child: _profileImage == null
                            ? Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.roleDisplayName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Chat button ─────────────────────────────────────────
                  if (me != null && me.uid != user.uid) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: Colors.white),
                        label: Text(
                          'ផ្ញើសារទៅ ${user.fullName}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.adminBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatRoomId: ChatRoom.buildId(me.uid, user.uid),
                              peerId: user.uid,
                              peerName: user.fullName,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Contact info card ───────────────────────────────────
                  _SectionCard(
                    title: 'ព័ត៌មានទំនាក់ទំនង',
                    children: [
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'អ៊ីមែល',
                          value: user.email),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'ទូរស័ព្ទ',
                          value: user.phoneNumber),
                      if (user.address != null &&
                          user.address!.isNotEmpty)
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'អាសយដ្ឋាន',
                            value: user.address!),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Account info ────────────────────────────────────────
                  _SectionCard(
                    title: 'ព័ត៌មានគណនី',
                    children: [
                      _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'តួនាទី',
                          value: user.roleDisplayName),
                      if (user.serviceType != null)
                        _InfoRow(
                            icon: Icons.work_outline,
                            label: 'ប្រភេទសេវា',
                            value: ServiceTypes.labelOf(user.serviceType!)),
                      _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'ចុះឈ្មោះ',
                          value:
                              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                      _InfoRow(
                          icon: user.isActive
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          label: 'ស្ថានភាព',
                          value: user.isActive ? 'សកម្ម' : 'ផ្អាក',
                          valueColor: user.isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.errorRed),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── ID Card ─────────────────────────────────────────────
                  _SectionCard(
                    title: 'អត្តសញ្ញាណប័ណ្ណ',
                    children: [
                      _IdCardSection(uid: user.uid),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? get _profileImage {
    if (user.profileImageUrl == null || user.profileImageUrl!.isEmpty) {
      return null;
    }
    try {
      return MemoryImage(base64Decode(user.profileImageUrl!));
    } catch (_) {
      return null;
    }
  }

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppTheme.adminBlue;
      case UserRole.farmer:
        return AppTheme.farmerGreen;
      case UserRole.serviceProvider:
        return AppTheme.providerOrange;
    }
  }

  // ── Delete this user (admin-only action) ──────────────────────────────────
  void _confirmAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('លុបអ្នកប្រើប្រាស់?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបគណនីរបស់ « ${user.fullName} » '
          '(${user.email}) មែនទេ? ទិន្នន័យទាំងអស់របស់អ្នកប្រើប្រាស់នេះ '
          'នឹងត្រូវលុបចេញពីប្រព័ន្ធជាស្ថាពរ និងមិនអាចត្រឡប់វិញបានទេ។',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // close confirm dialog
              final appProv = context.read<AppProvider>();
              final err = await appProv.deleteUser(user.uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err == null
                      ? 'បានលុបអ្នកប្រើប្រាស់ដោយជោគជ័យ ✓'
                      : err),
                  backgroundColor: err == null ? Colors.green : Colors.orange,
                ),
              );
              if (err == null && context.mounted) {
                Navigator.pop(context); // back out to the user list
              }
            },
            child: const Text('លុបចេញ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── ID Card fetcher widget ────────────────────────────────────────────────────

class _IdCardSection extends StatefulWidget {
  final String uid;
  const _IdCardSection({required this.uid});

  @override
  State<_IdCardSection> createState() => _IdCardSectionState();
}

class _IdCardSectionState extends State<_IdCardSection> {
  String? _frontBase64;
  String? _backBase64;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          _frontBase64 = data?['idCardFrontUrl'] as String?;
          _backBase64 = data?['idCardBackUrl'] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_frontBase64 == null && _backBase64 == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'មិនទាន់មានរូបភាពអត្តសញ្ញាណប័ណ្ណ',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    return Row(
      children: [
        if (_frontBase64 != null)
          Expanded(
              child: _IdCardImage(
                  base64: _frontBase64!, label: 'ខាងមុខ')),
        if (_frontBase64 != null && _backBase64 != null)
          const SizedBox(width: 10),
        if (_backBase64 != null)
          Expanded(
              child: _IdCardImage(
                  base64: _backBase64!, label: 'ខាងក្រោយ')),
      ],
    );
  }
}

class _IdCardImage extends StatelessWidget {
  final String base64;
  final String label;

  const _IdCardImage({required this.base64, required this.label});

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64);
    } catch (_) {}

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: bytes != null
              ? GestureDetector(
                  onTap: () => _showFull(context, bytes!),
                  child: Image.memory(
                    bytes,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  void _showFull(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...children.map((child) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: child,
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}