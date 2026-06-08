// lib/screens/provider/provider_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'home_screen.dart';

/// Provider home now wraps HomeScreen and adds a bottom nav tab
/// for Chat and Profile, keeping all existing HomeScreen functionality.
class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: the existing HomeScreen (all original provider UI)
          const HomeScreen(),
          // Tab 1: Chat list
          _buildChatTab(myUid),
          // Tab 2: Profile
          _buildProfileTab(user, auth),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: context.read<ChatProvider>().totalUnreadStream(myUid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: AppTheme.providerOrange,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'ទំព័រដើម',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.chat_bubble),
                label: 'ការសន្ទនា',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'គណនី',
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Chat tab ───────────────────────────────────────────────────────────────

  Widget _buildChatTab(String myUid) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('ការសន្ទនា'),
        backgroundColor: AppTheme.providerOrange,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List>(
        stream: context.read<ChatProvider>().threadsStream(myUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final threads = snap.data ?? [];

          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.providerOrange.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.forum_outlined,
                        size: 56,
                        color:
                            AppTheme.providerOrange.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'មិនទាន់មានការសន្ទនា',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'រង់ចាំការផ្ញើសារពីអ្នកគ្រប់គ្រង',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, indent: 72, color: Color(0xFFF0F0F0)),
            itemBuilder: (ctx, i) {
              final thread = threads[i];
              final unread = thread.unreadFor(myUid);
              final otherUid = thread.otherUid(myUid);
              final otherName = thread.otherName(myUid);
              final otherRole = thread.otherRole(myUid);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          AppTheme.adminBlue.withOpacity(0.15),
                      child: Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.adminBlue),
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  otherName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: unread > 0
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      _roleLabel(otherRole),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.adminBlue),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: unread > 0
                            ? AppTheme.textPrimary
                            : AppColors.textMuted,
                        fontWeight: unread > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  _formatDate(thread.lastMessageAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: unread > 0
                        ? AppTheme.providerOrange
                        : AppColors.textMuted,
                    fontWeight: unread > 0
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUid: otherUid,
                      otherName: otherName,
                      otherRole: otherRole,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Profile tab ────────────────────────────────────────────────────────────

  Widget _buildProfileTab(dynamic user, AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('គណនី'),
        backgroundColor: AppTheme.providerOrange,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.providerOrange.withOpacity(0.15),
              child: Text(
                user?.fullName?.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : '🚜',
                style: TextStyle(
                    fontSize:
                        user?.fullName?.isNotEmpty == true ? 36 : 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.providerOrange),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.fullName ?? '',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.providerOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.providerOrange.withOpacity(0.3)),
              ),
              child: const Text(
                'អ្នកផ្តល់សេវា',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.providerOrange),
              ),
            ),
            const SizedBox(height: 28),

            // Info card
            _profileCard([
              _profileRow(Icons.email_outlined, 'អ៊ីមែល',
                  user?.email ?? ''),
              _profileRow(Icons.phone_outlined, 'ទូរស័ព្ទ',
                  user?.phoneNumber ?? ''),
              if (user?.serviceType != null)
                _profileRow(Icons.work_outline, 'ប្រភេទសេវា',
                    user!.serviceType!),
              if (user?.address != null && user!.address!.isNotEmpty)
                _profileRow(Icons.location_on_outlined, 'អាសយដ្ឋាន',
                    user.address!),
            ]),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white),
                label: const Text('កែប្រែព័ត៌មាន',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.providerOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  context.read<AuthProvider>().refreshProfile();
                }),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout,
                    color: AppTheme.errorRed),
                label: const Text('ចេញពីគណនី',
                    style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
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
      child: Column(children: rows),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'អ្នកគ្រប់គ្រង';
      case 'farmer':
        return 'កសិករ';
      case 'serviceProvider':
        return 'អ្នកផ្តល់សេវា';
      default:
        return role;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}