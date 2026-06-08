// lib/screens/admin/user_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _search = '';
  UserRole? _filterRole; // null = all

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Filter bar ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search field
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'ស្វែងរកឈ្មោះ ឬ អ៊ីមែល...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Role filter chips
              Row(
                children: [
                  _filterChip(null, 'ទាំងអស់'),
                  const SizedBox(width: 8),
                  _filterChip(UserRole.farmer, 'កសិករ'),
                  const SizedBox(width: 8),
                  _filterChip(UserRole.serviceProvider, 'អ្នកផ្តល់សេវា'),
                  const SizedBox(width: 8),
                  _filterChip(UserRole.admin, 'Admin'),
                ],
              ),
            ],
          ),
        ),

        // ── User list from Firestore ──────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _buildEmpty();
              }

              var users = snap.data!.docs
                  .map((d) => UserModel.fromMap(
                      d.data() as Map<String, dynamic>, d.id))
                  .toList();

              // Apply role filter
              if (_filterRole != null) {
                users = users
                    .where((u) => u.role == _filterRole)
                    .toList();
              }

              // Apply search
              if (_search.isNotEmpty) {
                users = users.where((u) {
                  return u.fullName.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search) ||
                      u.phoneNumber.contains(_search);
                }).toList();
              }

              if (users.isEmpty) {
                return _buildEmpty(isFiltered: true);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 72, color: Color(0xFFF5F5F5)),
                itemBuilder: (ctx, i) => _UserTile(user: users[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(UserRole? role, String label) {
    final selected = _filterRole == role;
    final color = role == null
        ? AppTheme.adminBlue
        : role == UserRole.admin
            ? AppTheme.adminBlue
            : role == UserRole.farmer
                ? AppTheme.farmerGreen
                : AppTheme.providerOrange;

    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : const Color(0xFFDDDDDD)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? 'រកមិនឃើញអ្នកប្រើប្រាស់'
                : 'មិនទាន់មានអ្នកប្រើប្រាស់',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Individual user tile ──────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _roleColor.withOpacity(0.15),
        backgroundImage: user.profileImageUrl != null &&
                user.profileImageUrl!.isNotEmpty
            ? MemoryImage(base64Decode(user.profileImageUrl!))
            : null,
        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
            ? Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _roleColor),
              )
            : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.roleDisplayName,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _roleColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user.phoneNumber,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right,
          color: AppColors.textMuted, size: 20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: user)),
      ),
    );
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
}