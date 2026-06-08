// lib/screens/farmer/farmer_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

import '../chat/chat_screen.dart';
import '../profile/edit_profile_screen.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _currentIndex = 0;

  final List<_ServiceCategory> _categories = const [
    _ServiceCategory(icon: '🚜', label: 'ត្រាក់ទ័រ'),
    _ServiceCategory(icon: '🌾', label: 'ច្រូតស្រូវ'),
    _ServiceCategory(icon: '🛸', label: 'ដ្រូន'),
    _ServiceCategory(icon: '🛠', label: 'គោយន្ត'),
    _ServiceCategory(icon: '💨', label: 'បាញ់ថ្នាំ'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: AppTheme.farmerGreen,
        actions: [
          // Chat icon with unread badge
          StreamBuilder<int>(
            stream: context.read<ChatProvider>().totalUnreadStream(myUid),
            builder: (ctx, snap) {
              final unread = snap.data ?? 0;
              return IconButton(
                tooltip: 'ការសន្ទនា',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
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
                onPressed: () => _showChatList(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ចេញ',
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showRequestJobDialog(context),
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('ស្នើសុំសេវា',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'KhmerOSBattambang')),
            )
          : null,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHome(user),
            _buildMyJobs(),
            _buildProfile(user),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.farmerGreen,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ទំព័រដើម',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'ការងាររបស់ខ្ញុំ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'ប្រវត្តិរូប',
          ),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'កសិករ';
      case 1:
        return 'ការងាររបស់ខ្ញុំ';
      case 2:
        return 'ប្រវត្តិរូប';
      default:
        return 'កសិករ';
    }
  }

  // ── Chat list bottom sheet ─────────────────────────────────────────────────

  void _showChatList(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.pop(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (ctx, scrollCtrl) => GestureDetector(
            onTap: () {},
            child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              const SizedBox(height: 12),
              const Text(
                'ការសន្ទនា',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Divider(height: 16),
              Expanded(
                child: StreamBuilder<List<ChatRoom>>(
                  stream: context
                      .read<ChatProvider>()
                      .getChatRooms(myUid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final rooms = snap.data ?? [];
                    if (rooms.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💬',
                                style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(
                              'មិនទាន់មានការសន្ទនា',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }
                    final chatProv = context.read<ChatProvider>();
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 70,
                          color: Color(0xFFF5F5F5)),
                      itemBuilder: (ctx2, i) {
                        final room = rooms[i];
                        final otherUid = room.otherUid(myUid);
                        return FutureBuilder<String>(
                          future: chatProv.getUserName(otherUid),
                          builder: (ctx3, nameSnap) {
                            final otherName = nameSnap.data ?? '...';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.adminBlue.withValues(alpha: 0.15),
                                child: Text(
                                  otherName.isNotEmpty
                                      ? otherName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.adminBlue),
                                ),
                              ),
                              title: Text(
                                otherName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                room.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatRoomId: room.id,
                                      peerId: otherUid,
                                      peerName: otherName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  // ── Home tab ───────────────────────────────────────────────────────────────

  Widget _buildHome(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.farmerGreen, Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.farmerGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user?.profileImageUrl != null &&
                          user!.profileImageUrl!.isNotEmpty
                      ? MemoryImage(base64Decode(user.profileImageUrl!))
                      : null,
                  child: user?.profileImageUrl == null ||
                          user!.profileImageUrl!.isEmpty
                      ? const Text('👨‍🌾',
                          style: TextStyle(fontSize: 28))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ស្វាគមន៍, ${user?.fullName ?? 'កសិករ'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ស្វែងរកសេវាកសិកម្មជិតអ្នក',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppTheme.textSecondary),
                SizedBox(width: 12),
                Text(
                  'ស្វែងរកសេវាកម្ម...',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories
          const Text(
            'ប្រភេទសេវាកម្ម',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => _showRequestJobDialog(context,
                      preselect: cat.label),
                  child: Container(
                    width: 80,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primaryGreen
                              .withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(cat.icon,
                            style:
                                const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          cat.label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Recent jobs summary
          const Text(
            'ការងាររបស់ខ្ញុំ (ថ្មីៗ)',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Consumer2<AuthProvider, AppProvider>(
            builder: (context, auth, appProv, _) {
              final uid = auth.currentUser?.uid ?? '';
              final myTractor =
                  appProv.tractorJobsForFarmer(uid).take(2).toList();
              final myDrone =
                  appProv.droneJobsForFarmer(uid).take(2).toList();

              if (myTractor.isEmpty && myDrone.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Text('📋',
                            style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text(
                          'មិនទាន់មានការស្នើសុំ\nចុចប៊ូតុង "ស្នើសុំសេវា" ខាងក្រោម',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...myTractor.map((j) => _buildJobTile(
                        emoji: '🚜',
                        title: j.serviceType,
                        subtitle: j.location,
                        date: j.scheduledDate,
                        statusLabel: j.statusLabel,
                        statusColor: j.statusColor,
                      )),
                  ...myDrone.map((j) => _buildJobTile(
                        emoji: '🛸',
                        title: 'ដ្រូនបាញ់ — ${j.cropType}',
                        subtitle: j.location,
                        date: j.scheduledDate,
                        statusLabel: j.statusLabel,
                        statusColor: j.statusColor,
                      )),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── My Jobs tab ────────────────────────────────────────────────────────────

  Widget _buildMyJobs() {
    return Consumer2<AuthProvider, AppProvider>(
      builder: (context, auth, appProv, _) {
        final uid = auth.currentUser?.uid ?? '';
        final myTractor = appProv.tractorJobsForFarmer(uid);
        final myDrone = appProv.droneJobsForFarmer(uid);

        if (myTractor.isEmpty && myDrone.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text(
                  'អ្នកមិនទាន់មានការស្នើសុំ',
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (myTractor.isNotEmpty) ...[
              const Text('ការស្នើសុំត្រាក់ទ័រ',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...myTractor.map((j) => _buildJobTile(
                    emoji: '🚜',
                    title: j.serviceType,
                    subtitle: '${j.location} • ${j.areaHectares} ហិចតា',
                    date: '${j.scheduledDate} • ${j.scheduledTime}',
                    statusLabel: j.statusLabel,
                    statusColor: j.statusColor,
                  )),
              const SizedBox(height: 16),
            ],
            if (myDrone.isNotEmpty) ...[
              const Text('ការស្នើសុំដ្រូន',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...myDrone.map((j) => _buildJobTile(
                    emoji: '🛸',
                    title: '${j.cropType} — ${j.pesticide}',
                    subtitle: '${j.location} • ${j.areaHectares} ហិចតា',
                    date: '${j.scheduledDate} • ${j.scheduledTime}',
                    statusLabel: j.statusLabel,
                    statusColor: j.statusColor,
                  )),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  // ── Profile tab ────────────────────────────────────────────────────────────

  Widget _buildProfile(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.farmerGreen.withOpacity(0.15),
            backgroundImage: user?.profileImageUrl != null &&
                    user!.profileImageUrl!.isNotEmpty
                ? MemoryImage(base64Decode(user.profileImageUrl!))
                : null,
            child: user?.profileImageUrl == null ||
                    user!.profileImageUrl!.isEmpty
                ? Text(
                    user?.fullName?.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : '👨‍🌾',
                    style: TextStyle(
                        fontSize: user?.fullName?.isNotEmpty == true ? 36 : 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.farmerGreen),
                  )
                : null,
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
              color: AppTheme.farmerGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.farmerGreen.withOpacity(0.3)),
            ),
            child: Text(
              user?.roleDisplayName ?? 'កសិករ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.farmerGreen),
            ),
          ),
          const SizedBox(height: 28),

          // Info card
          _profileCard([
            _profileRow(Icons.email_outlined, 'អ៊ីមែល', user?.email ?? ''),
            _profileRow(
                Icons.phone_outlined, 'ទូរស័ព្ទ', user?.phoneNumber ?? ''),
            if (user?.address != null && user!.address!.isNotEmpty)
              _profileRow(Icons.location_on_outlined, 'អាសយដ្ឋាន',
                  user.address!),
          ]),
          const SizedBox(height: 16),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('កែប្រែព័ត៌មាន',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.farmerGreen,
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

          // Logout button
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
                final auth = context.read<AuthProvider>();
                await auth.logout();
              },
            ),
          ),
        ],
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

  // ── Shared job tile ────────────────────────────────────────────────────────

  Widget _buildJobTile({
    required String emoji,
    required String title,
    required String subtitle,
    required String date,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit job dialog ──────────────────────────────────────────────────────

  void _showRequestJobDialog(BuildContext context, {String? preselect}) {
    final auth = context.read<AuthProvider>();
    final appProv = context.read<AppProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    String selectedType =
        (preselect == 'ដ្រូន' || preselect == 'បាញ់ថ្នាំ')
            ? 'drone'
            : 'tractor';
    final locationCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    final cropCtrl = TextEditingController(text: 'ស្រូវ');
    final pesticideCtrl = TextEditingController();
    final tractorOptions = ['ភ្ជួរស្រែ', 'ច្រូតស្រូវ', 'ដាំស្រូវ', 'ជីកបង្ហូរ'];
    String tractorService = tractorOptions.contains(preselect)
        ? preselect!
        : 'ភ្ជួរស្រែ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ស្នើសុំសេវា',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                            () => selectedType = 'tractor'),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'tractor'
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.primaryGreen),
                          ),
                          child: const Center(
                            child: Text('🚜 ត្រាក់ទ័រ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                            () => selectedType = 'drone'),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedType == 'drone'
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.primaryGreen),
                          ),
                          child: const Center(
                            child: Text('🛸 ដ្រូន',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedType == 'tractor') ...[
                  DropdownButtonFormField<String>(
                    initialValue: tractorService,
                    decoration: const InputDecoration(
                        labelText: 'ប្រភេទការងារ'),
                    items: [
                      'ភ្ជួរស្រែ',
                      'ច្រូតស្រូវ',
                      'ដាំស្រូវ',
                      'ជីកបង្ហូរ'
                    ]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => tractorService = v!),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: cropCtrl,
                    decoration: const InputDecoration(
                        labelText: 'ប្រភេទដំណាំ'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pesticideCtrl,
                    decoration: const InputDecoration(
                        labelText: 'ប្រភេទថ្នាំ'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'ទីតាំង (ភូមិ/ឃុំ/ស្រុក)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                            labelText: 'ថ្ងៃខែ (DD/MM/YYYY)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(
                            labelText: 'ម៉ោង'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'ផ្ទៃដីជាហិចតា',
                      suffixText: 'ហិចតា'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'កំណត់ចំណាំ (ជាជម្រើស)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize:
                          const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      String? err;
                      if (selectedType == 'tractor') {
                        err = await appProv.addTractorJob(
                          farmerUid: user.uid,
                          farmerName: user.fullName,
                          location: locationCtrl.text.trim(),
                          serviceType: tractorService,
                          scheduledDate: dateCtrl.text.trim(),
                          scheduledTime: timeCtrl.text.trim(),
                          areaHectares:
                              double.tryParse(areaCtrl.text) ??
                                  1.0,
                          notes: notesCtrl.text.trim(),
                        );
                      } else {
                        err = await appProv.addDroneJob(
                          farmerUid: user.uid,
                          farmerName: user.fullName,
                          location: locationCtrl.text.trim(),
                          cropType: cropCtrl.text.trim(),
                          pesticide: pesticideCtrl.text.trim(),
                          scheduledDate: dateCtrl.text.trim(),
                          scheduledTime: timeCtrl.text.trim(),
                          areaHectares:
                              double.tryParse(areaCtrl.text) ??
                                  1.0,
                          notes: notesCtrl.text.trim(),
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ??
                                'បានផ្ញើការស្នើសុំដោយជោគជ័យ! 🎉'),
                            backgroundColor: err == null
                                ? AppTheme.primaryGreen
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('ផ្ញើការស្នើសុំ',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'KhmerOSBattambang',
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCategory {
  final String icon;
  final String label;
  const _ServiceCategory({required this.icon, required this.label});
}