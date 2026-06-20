// lib/screens/provider/tabs/profile_tab.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/service_request.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import '../../profile/edit_profile_screen.dart';
import '../../auth/auth_wrapper.dart';

/// Profile tab for the Service Provider role.
///
/// Reads live from [AuthProvider.currentUser] (Firestore-backed) so name,
/// avatar, phone, address, and active service type always reflect whatever
/// the provider last saved — there is no cached/static copy anywhere here.
class ProviderProfileTab extends StatelessWidget {
  const ProviderProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    ImageProvider? avatar;
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.profileImageUrl!));
      } catch (_) {}
    }

    final serviceInfo = user?.serviceType != null
        ? ServiceTypes.infoOf(user!.serviceType!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('គណនី',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.providerOrange.withOpacity(0.15),
            backgroundImage: avatar,
            child: avatar == null
                ? Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '🚜',
                    style: TextStyle(
                        fontSize: user?.fullName.isNotEmpty == true ? 34 : 44,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.providerOrange),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(user?.fullName ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.providerOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.providerOrange.withOpacity(0.3)),
            ),
            child: Text(user?.roleDisplayName ?? 'អ្នកផ្តល់សេវា',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.providerOrange)),
          ),

          if (serviceInfo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (serviceInfo['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(serviceInfo['icon'] as IconData, size: 14, color: serviceInfo['color'] as Color),
                const SizedBox(width: 6),
                Text(serviceInfo['label'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: serviceInfo['color'] as Color)),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          _ProfileInfoCard(children: [
            _InfoRow(icon: Icons.email_outlined, label: 'អ៊ីមែល', value: user?.email ?? '-'),
            _InfoRow(icon: Icons.phone_outlined, label: 'ទូរស័ព្ទ', value: user?.phoneNumber ?? '-'),
            if (user?.address != null && user!.address!.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, label: 'អាសយដ្ឋាន', value: user.address!),
          ]),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('កែប្រែព័ត៌មាន',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.providerOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                  .then((_) => context.read<AuthProvider>().refreshProfile()),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              label: const Text('ចាកចេញ', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmLogout(context, auth),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ចាកចេញពីប្រព័ន្ធ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('តើអ្នកប្រាកដថាចង់ចាកចេញពីប្រព័ន្ធមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ទេ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (_) => false,
                );
              }
            },
            child: const Text('បាទ ចាកចេញ'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileInfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E8E8)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}
