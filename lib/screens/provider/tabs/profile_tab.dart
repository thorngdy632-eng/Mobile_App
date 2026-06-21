// lib/screens/provider/tabs/profile_tab.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/service_request.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';
import '../../profile/edit_profile_screen.dart';
import '../../chat/chat_screen.dart';
import '../../auth/auth_wrapper.dart';

class _ImgCfg {
  final String imagePath;
  const _ImgCfg(this.imagePath);
}

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png'),
  'harvesting':  _ImgCfg('assets/images/2.png'),
  'drone_spray': _ImgCfg('assets/images/5.png'),
  'transport':   _ImgCfg('assets/images/3.png'),
  'irrigation':  _ImgCfg('assets/images/4.png'),
};

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Cover Image ──
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.providerOrange.withValues(alpha: 0.8),
                        AppTheme.providerOrange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (() {
                        if (user?.coverImageUrl != null && user!.coverImageUrl!.isNotEmpty) {
                          try {
                            return Image.memory(
                              base64Decode(user.coverImageUrl!),
                              fit: BoxFit.cover,
                            );
                          } catch (_) {}
                        }
                        return const SizedBox.shrink();
                      })(),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Edit cover button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ).then((_) => context.read<AuthProvider>().refreshProfile()),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      // Centered avatar overlapping cover
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: avatar == null
                                      ? const LinearGradient(
                                    colors: [AppTheme.providerOrange, Color(0xFFFFB74D)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : null,
                                  shape: BoxShape.circle,
                                ),
                                child: avatar != null
                                    ? Image(image: avatar, fit: BoxFit.cover)
                                    : Center(
                                      child: Text(
                                        user?.fullName.isNotEmpty == true
                                            ? user!.fullName[0].toUpperCase()
                                            : 'tractor',
                                        style: const TextStyle(
                                          fontSize: 32, fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Name / Role / Service ──
                Padding(
                  padding: const EdgeInsets.only(top: 50, bottom: 0, left: 16, right: 16),
                  child: Column(
                    children: [
                      Text(user?.fullName ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.providerOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(user?.roleDisplayName ?? 'អ្នកផ្តល់សេវា',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.providerOrange)),
                      ),
                      if (serviceInfo != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (serviceInfo['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                _serviceImgCfgs[user?.serviceType]?.imagePath ?? 'assets/images/app_icon.png',
                                width: 16, height: 16, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(serviceInfo['icon'] as IconData, size: 14, color: serviceInfo['color'] as Color),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(serviceInfo['label'] as String,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: serviceInfo['color'] as Color)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Column(children: [
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
                    icon: const Icon(Icons.support_agent_rounded, color: Color(0xFFD32F2F)),
                    label: const Text('ទាក់ទងអ្នកគ្រប់គ្រង',
                        style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _contactAdmin(context, user),
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
          ),
        ],
      ),
    );
  }

  // ── Find the admin account and open (or create) a chat with them ─────────
  Future<void> _contactAdmin(BuildContext context, dynamic user) async {
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.providerOrange),
      ),
    );

    try {
      final adminSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (context.mounted) Navigator.pop(context); // close loading dialog

      if (adminSnap.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('មិនអាចរកឃើញគណនីអ្នកគ្រប់គ្រងបានទេ'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      final adminDoc = adminSnap.docs.first;
      final adminUid = adminDoc.id;
      final adminName = adminDoc.data()['fullName'] as String? ?? 'អ្នកគ្រប់គ្រង';

      if (!context.mounted) return;
      final chatProv = context.read<ChatProvider>();
      final chatRoomId = await chatProv.ensureChatRoom(
        myUid: user.uid as String,
        peerId: adminUid,
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            peerId: adminUid,
            peerName: adminName,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មានបញ្ហា: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
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