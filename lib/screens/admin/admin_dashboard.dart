import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/service_request.dart';
import '../chat/admin_chat_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../auth/auth_wrapper.dart';
import 'user_list_screen.dart';
import 'admin_statistics_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kNavyDeep    = Color(0xFF0A1628);
const _kNavyMid     = Color(0xFF0F2040);
const _kAccentBlue  = Color(0xFF3B82F6);
const _kAccentCyan  = Color(0xFF06B6D4);
const _kAccentGreen = Color(0xFF10B981);
const _kAccentAmber = Color(0xFFF59E0B);
const _kAccentRed   = Color(0xFFEF4444);
const _kAccentPurple= Color(0xFF8B5CF6);
const _kSurface     = Color(0xFF1E2D45);
const _kBorder      = Color(0xFF2A3F5F);
const _kTextPrimary = Color(0xFFF1F5F9);
const _kTextSecondary = Color(0xFF94A3B8);
const _kTextMuted   = Color(0xFF64748B);

const Map<String, String> _serviceImages = {
  'plowing':     'assets/images/1.png',
  'harvesting':  'assets/images/2.png',
  'transport':   'assets/images/3.png',
  'irrigation':  'assets/images/4.png',
  'drone_spray': 'assets/images/5.png',
};

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_currentIndex == i) return;
    _fadeCtrl.reset();
    setState(() => _currentIndex = i);
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _kNavyDeep,
      ),
      child: Scaffold(
        backgroundColor: _kNavyDeep,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: _buildBody(user),
        ),
        bottomNavigationBar: _buildBottomNav(myUid),
      ),
    );
  }

  Widget _buildBody(dynamic user) {
    switch (_currentIndex) {
      case 0: return _DashboardTab(user: user, onSwitchTab: _switchTab);
      case 1: return const _PromotionTab();
      case 2: return const _UsersTab();
      case 3: return const _ChatTab();
      case 4: return _SettingsTab(user: user);
      default: return const SizedBox();
    }
  }

  Widget _buildBottomNav(String myUid) {
    return StreamBuilder<int>(
      stream: context.read<ChatProvider>().totalUnreadStream(myUid),
      builder: (context, snap) {
        final unread = snap.data ?? 0;
        return Container(
          decoration: const BoxDecoration(
            color: _kNavyMid,
            border: Border(top: BorderSide(color: _kBorder, width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(icon: Icons.dashboard_rounded,        label: 'ផ្ទាំងគ្រប់គ្រង', index: 0, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.campaign_rounded,         label: 'ការផ្សព្វផ្សាយ',  index: 1, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.people_alt_rounded,       label: 'អ្នកប្រើ',         index: 2, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.chat_rounded,             label: 'ការសន្ទនា',        index: 3, current: _currentIndex, onTap: _switchTab, badge: unread),
                  _NavItem(icon: Icons.settings_rounded,         label: 'ការកំណត់',         index: 4, current: _currentIndex, onTap: _switchTab),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav item widget ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final int badge;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.current, required this.onTap, this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(index); },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: active
                        ? _kAccentBlue.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                    size: 22,
                    color: active ? _kAccentBlue : _kTextMuted,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -3, right: -3,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: _kAccentRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text(badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 8,
                              fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? _kAccentBlue : _kTextMuted,
                ),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final dynamic user;
  final ValueChanged<int> onSwitchTab;

  const _DashboardTab({required this.user, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, ChatProvider>(
      builder: (context, appProv, chatProv, _) {
        final myUid = context.read<AuthProvider>().currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
        final requests = appProv.serviceRequests;
        final totalJobs = requests.length;
        final pending = requests.where((r) => r.status == 'pending').length;
        final confirmed = requests.where((r) => r.status == 'accepted').length;
        final completed = requests.where((r) => r.status == 'completed').length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, myUid, chatProv)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('អ្នកប្រើប្រាស់'),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
                          ),
                          child: const Text('មើលស្ថិតិលម្អិត →',
                            style: TextStyle(fontSize: 12, color: _kAccentBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '${appProv.totalUsersCount}', label: 'អ្នកប្រើប្រាស់សរុប', icon: Icons.groups_rounded, color: _kAccentBlue)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '${appProv.totalFarmersCount}', label: 'កសិករ', icon: Icons.agriculture_rounded, color: _kAccentGreen)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '${appProv.totalServiceProvidersCount}', label: 'អ្នកផ្តល់សេវា', icon: Icons.engineering_rounded, color: _kAccentAmber)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '${appProv.totalAdminsCount}', label: 'អ្នកគ្រប់គ្រង', icon: Icons.admin_panel_settings_rounded, color: _kAccentPurple)),
                    ]),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _sectionTitle('ទិដ្ឋភាពសង្ខេប'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '$totalJobs', label: 'ការស្នើសុំសរុប', icon: Icons.assignment_rounded, color: _kAccentBlue)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '$pending', label: 'រង់ចាំ', icon: Icons.hourglass_top_rounded, color: _kAccentAmber)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '$confirmed', label: 'បានទទួល', icon: Icons.check_circle_rounded, color: _kAccentGreen)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '$completed', label: 'បានបញ្ចប់', icon: Icons.task_alt_rounded, color: _kAccentCyan)),
                    ]),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('ដំណើរការរហ័ស'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _QuickAction(icon: Icons.campaign_rounded,         label: 'ការផ្សព្វ\nផ្សាយ',  color: _kAccentAmber,  onTap: () => onSwitchTab(1)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.people_alt_rounded,       label: 'អ្នកប្រើ\nប្រាស់', color: _kAccentPurple, onTap: () => onSwitchTab(2)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.chat_rounded,             label: 'ការ\nសន្ទនា',   color: _kAccentCyan,   onTap: () => onSwitchTab(3)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.bar_chart_rounded,        label: 'ស្ថិតិ\nព័ត៌មាន', color: _kAccentGreen,  onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
                      )),
                    ]),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _LiveActivityCard(appProv: appProv),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String myUid, ChatProvider chatProv) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) greeting = 'អរុណសួស្ដី';
    else if (hour < 17) greeting = 'ទិវាសួស្ដី';
    else greeting = 'សាយណ្ហសួស្ដី';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavyMid, _kNavyDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 14, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: user?.profileImageUrl != null &&
                            user!.profileImageUrl!.isNotEmpty
                        ? null
                        : const LinearGradient(
                      colors: [_kAccentBlue, _kAccentCyan],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: _kAccentBlue.withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: user?.profileImageUrl != null &&
                          user!.profileImageUrl!.isNotEmpty
                      ? Image.memory(
                          base64Decode(user.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            user?.fullName?.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w800),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                      style: const TextStyle(
                        fontSize: 12, color: _kTextSecondary)),
                    Text(
                      user?.fullName ?? 'Administrator',
                      style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: _kTextPrimary),
                    ),
                  ],
                ),
              ),
              StreamBuilder<int>(
                stream: chatProv.totalUnreadStream(myUid),
                builder: (ctx, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderIconBtn(
                        icon: Icons.notifications_rounded,
                        onTap: () => onSwitchTab(3),
                      ),
                      if (count > 0)
                        Positioned(
                          top: 2, right: 2,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: _kAccentRed, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.person_rounded,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshProfile();
                  }
                }),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kAccentGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kAccentGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: _kAccentGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('ប្រព័ន្ធដំណើរការធម្មតា',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _kAccentGreen)),
                const Spacer(),
                Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: const TextStyle(fontSize: 11, color: _kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: _kSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder)),
      child: Icon(icon, color: _kTextSecondary, size: 20),
    ),
  );
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.value, required this.label,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: _kTextPrimary, height: 1)),
              const SizedBox(height: 3),
              Text(label,
                style: const TextStyle(
                  fontSize: 11, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label,
    required this.color, required this.onTap, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (count > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: _kAccentRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10, color: _kTextSecondary, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live activity card (reads from serviceRequests) ────────────────────────

class _LiveActivityCard extends StatelessWidget {
  final AppProvider appProv;
  const _LiveActivityCard({required this.appProv});

  @override
  Widget build(BuildContext context) {
    final all = appProv.serviceRequests
        .where((r) => r.status != 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      decoration: BoxDecoration(
        color: _kSurface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 18, color: _kAccentCyan),
                const SizedBox(width: 8),
                const Text('សកម្មភាពចុងក្រោយ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary)),
              ],
            ),
          ),
          if (all.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('មិនទាន់មានសកម្មភាព',
                    style: TextStyle(color: _kTextMuted, fontSize: 13)),
              ),
            )
          else
            ...List.generate(all.length > 5 ? 5 : all.length, (i) {
              final r = all[i];
              final isLast = i == (all.length > 5 ? 4 : all.length - 1);
              final info = ServiceTypes.infoOf(r.serviceType);
              final label = info['label'] as String? ?? r.serviceType;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: (info['color'] as Color? ?? _kAccentBlue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              _serviceImages[r.serviceType] ?? 'assets/images/app_icon.png',
                              width: 32, height: 32, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                info['icon'] as IconData? ?? Icons.work_outline,
                                color: info['color'] as Color? ?? _kAccentBlue, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$label — ${r.farmerName}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: _kTextPrimary)),
                              const SizedBox(height: 2),
                              Text(_timeAgo(r.createdAt),
                                  style: const TextStyle(
                                      fontSize: 10, color: _kTextMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: r.status),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: _kBorder, indent: 58),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} នាទីមុន';
    if (diff.inHours < 24) return '${diff.inHours} ម៉ោងមុន';
    return '${diff.inDays} ថ្ងៃមុន';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c; String l;
    switch (status) {
      case 'confirmed': c = _kAccentGreen;  l = 'បញ្ជាក់'; break;
      case 'completed': c = _kAccentBlue;   l = 'បញ្ចប់';  break;
      case 'cancelled': c = _kAccentRed;    l = 'បោះបង់';  break;
      default:          c = _kAccentAmber;  l = 'រង់ចាំ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35))),
      child: Text(l, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — PROMOTIONS (replaces old Jobs/Requests tab)
// ═══════════════════════════════════════════════════════════════════════════════

/// Promotion model
class _PromoModel {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String iconName;
  final DateTime createdAt;
  final bool isActive;

  const _PromoModel({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.iconName,
    required this.createdAt,
    required this.isActive,
  });

  factory _PromoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _PromoModel(
      id: doc.id,
      tag: d['tag'] ?? '',
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      accentColor: Color(d['accentColor'] ?? 0xFFFF7043),
      iconName: d['iconName'] ?? 'verified',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
    );
  }
}

// Accent colour presets shown in the form
const List<Map<String, dynamic>> _kColorPresets = [
  {'label': 'ទឹកក្រូច', 'color': Color(0xFFFF7043)},
  {'label': 'បخضر',      'color': Color(0xFF66BB6A)},
  {'label': 'ខៀវ',       'color': Color(0xFF42A5F5)},
  {'label': 'មាស',       'color': Color(0xFFFFC107)},
  {'label': 'ស្វាយ',     'color': Color(0xFFAB47BC)},
  {'label': 'ក្រហម',     'color': Color(0xFFEF5350)},
];

// Icon presets
const List<Map<String, dynamic>> _kIconPresets = [
  {'name': 'verified',    'icon': Icons.verified_outlined},
  {'name': 'agriculture', 'icon': Icons.agriculture_outlined},
  {'name': 'campaign',    'icon': Icons.campaign_outlined},
  {'name': 'star',        'icon': Icons.star_outline},
  {'name': 'discount',    'icon': Icons.discount_outlined},
  {'name': 'bolt',        'icon': Icons.bolt_outlined},
];

IconData _iconFromName(String name) {
  final found = _kIconPresets.firstWhere(
    (e) => e['name'] == name,
    orElse: () => _kIconPresets.first,
  );
  return found['icon'] as IconData;
}

class _PromotionTab extends StatefulWidget {
  const _PromotionTab();
  @override
  State<_PromotionTab> createState() => _PromotionTabState();
}

class _PromotionTabState extends State<_PromotionTab> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          color: _kNavyMid,
          padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 12, 16, 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ការផ្សព្វផ្សាយ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: _kTextPrimary)),
                    SizedBox(height: 2),
                    Text('ផ្ញើទៅកសិករទាំងអស់ភ្លាមៗ',
                      style: TextStyle(fontSize: 11, color: _kTextSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _showForm
                        ? _kAccentRed.withOpacity(0.15)
                        : _kAccentAmber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showForm
                          ? _kAccentRed.withOpacity(0.4)
                          : _kAccentAmber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showForm ? Icons.close_rounded : Icons.add_rounded,
                        color: _showForm ? _kAccentRed : _kAccentAmber,
                        size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _showForm ? 'បិទ' : 'បន្ថែម',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: _showForm ? _kAccentRed : _kAccentAmber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Create form (collapsible) ─────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showForm
                    ? _CreatePromoForm(
                        onCreated: () => setState(() => _showForm = false),
                      )
                    : const SizedBox.shrink(),
              ),

              if (_showForm) const SizedBox(height: 20),

              // ── Live promo list ───────────────────────────────────────
              _sectionTitle('ការផ្សព្វផ្សាយទាំងអស់'),
              const SizedBox(height: 12),
              _PromoList(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Create Promo Form ────────────────────────────────────────────────────────

class _CreatePromoForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreatePromoForm({required this.onCreated});

  @override
  State<_CreatePromoForm> createState() => _CreatePromoFormState();
}

class _CreatePromoFormState extends State<_CreatePromoForm> {
  final _tagCtrl      = TextEditingController();
  final _titleCtrl    = TextEditingController();
  final _subtitleCtrl = TextEditingController();

  Color _selectedColor = const Color(0xFFFF7043);
  String _selectedIcon = 'verified';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _tagCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final tag      = _tagCtrl.text.trim();
    final title    = _titleCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();

    if (tag.isEmpty || title.isEmpty || subtitle.isEmpty) {
      setState(() => _error = 'សូមបំពេញព័ត៌មានទាំងអស់');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      await FirebaseFirestore.instance.collection('promotions').add({
        'tag':         tag,
        'title':       title,
        'subtitle':    subtitle,
        'accentColor': _selectedColor.value,
        'iconName':    _selectedIcon,
        'isActive':    true,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានបន្ថែមការផ្សព្វផ្សាយ ✓  — កសិករទាំងអស់ទទួលបានដោយស្វ័យប្រវត្តិ'),
            backgroundColor: _kAccentGreen,
          ),
        );
        widget.onCreated();
      }
    } catch (e) {
      setState(() { _submitting = false; _error = 'មានបញ្ហា: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kAccentAmber.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: _kAccentAmber.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kAccentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.campaign_rounded, color: _kAccentAmber, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('បង្កើតការផ្សព្វផ្សាយថ្មី',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          _tagCtrl.text.isEmpty ? 'ស្លាក...' : _tagCtrl.text,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _titleCtrl.text.isEmpty ? 'ចំណងជើង...' : _titleCtrl.text,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.35)),
                      const SizedBox(height: 5),
                      Text(
                        _subtitleCtrl.text.isEmpty ? 'អនុចំណងជើង...' : _subtitleCtrl.text,
                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                  child: Icon(_iconFromName(_selectedIcon), color: Colors.white70, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tag ──
          _FormLabel('ស្លាក (Tag)'),
          const SizedBox(height: 6),
          _FormField(
            controller: _tagCtrl,
            hint: 'ឧ. ចំណេញ ១០០%  ·  ថ្មី  ·  បញ្ចុះតម្លៃ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // ── Title ──
          _FormLabel('ចំណងជើង'),
          const SizedBox(height: 6),
          _FormField(
            controller: _titleCtrl,
            hint: 'ឧ. ជួលត្រាក់ទ័រ Kubota តម្លៃពិសេស',
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // ── Subtitle ──
          _FormLabel('អនុចំណងជើង'),
          const SizedBox(height: 6),
          _FormField(
            controller: _subtitleCtrl,
            hint: 'ឧ. ធ្វើការ · ABA · KHQR',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),

          // ── Colour picker ──
          _FormLabel('ពណ៌ស្លាក'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _kColorPresets.map((preset) {
              final c = preset['color'] as Color;
              final selected = c.value == _selectedColor.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 3),
                    boxShadow: selected
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // ── Icon picker ──
          _FormLabel('រូបតំណាង'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _kIconPresets.map((preset) {
              final name = preset['name'] as String;
              final icon = preset['icon'] as IconData;
              final selected = name == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? _kAccentAmber.withOpacity(0.2)
                        : _kNavyMid,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _kAccentAmber : _kBorder),
                  ),
                  child: Icon(icon,
                    color: selected ? _kAccentAmber : _kTextMuted,
                    size: 22),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: _kAccentRed, fontSize: 12)),
            const SizedBox(height: 12),
          ],

          // ── Submit button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentAmber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('ផ្ញើទៅកសិករទាំងអស់',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
      color: _kTextSecondary));
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final void Function(String) onChanged;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: _kTextPrimary, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kTextMuted, fontSize: 12),
      filled: true,
      fillColor: _kNavyMid,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccentAmber)),
    ),
  );
}

// ─── Live promo list (from Firestore) ─────────────────────────────────────────

class _PromoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promotions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kAccentAmber),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: const Column(
              children: [
                Text('📢', style: TextStyle(fontSize: 36)),
                SizedBox(height: 12),
                Text('មិនទាន់មានការផ្សព្វផ្សាយ',
                  style: TextStyle(color: _kTextMuted, fontSize: 13)),
                SizedBox(height: 4),
                Text('ចុច «បន្ថែម» ដើម្បីបង្កើតការផ្សព្វផ្សាយដំបូង',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextMuted, fontSize: 11, height: 1.5)),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final promo = _PromoModel.fromDoc(doc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PromoCard(promo: promo),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final _PromoModel promo;
  const _PromoCard({required this.promo});

  Future<void> _toggleActive(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(promo.id)
          .update({'isActive': !promo.isActive});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មានបញ្ហា: $e'), backgroundColor: _kAccentRed));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kAccentRed, size: 24),
            SizedBox(width: 10),
            Text('លុបការផ្សព្វផ្សាយ?',
              style: TextStyle(color: _kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('ការផ្សព្វផ្សាយនេះនឹងត្រូវបានលុបចេញពីរបស់កសិករទាំងអស់។',
          style: TextStyle(color: _kTextSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('បោះបង់', style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('លុប', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('promotions')
            .doc(promo.id)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('បានលុបការផ្សព្វផ្សាយ ✓'),
              backgroundColor: _kAccentGreen));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('មានបញ្ហា: $e'), backgroundColor: _kAccentRed));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: promo.isActive
              ? _kAccentAmber.withOpacity(0.35)
              : _kBorder),
      ),
      child: Column(
        children: [
          // Mini preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: promo.accentColor,
                            borderRadius: BorderRadius.circular(5)),
                          child: Text(promo.tag,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Text(promo.title,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w700, height: 1.3)),
                        const SizedBox(height: 4),
                        Text(promo.subtitle,
                          style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(_iconFromName(promo.iconName), color: Colors.white70, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: promo.isActive
                        ? _kAccentGreen.withOpacity(0.15)
                        : _kTextMuted.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: promo.isActive
                          ? _kAccentGreen.withOpacity(0.4)
                          : _kTextMuted.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: promo.isActive ? _kAccentGreen : _kTextMuted,
                          shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        promo.isActive ? 'សកម្ម' : 'អសកម្ម',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: promo.isActive ? _kAccentGreen : _kTextMuted)),
                    ],
                  ),
                ),
                const Spacer(),
                // Toggle
                GestureDetector(
                  onTap: () => _toggleActive(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kNavyMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          promo.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: _kTextSecondary, size: 16),
                        const SizedBox(width: 4),
                        Text(promo.isActive ? 'ផ្អាក' : 'បើក',
                          style: const TextStyle(fontSize: 11, color: _kTextSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: () => _delete(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _kAccentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kAccentRed.withOpacity(0.3))),
                    child: const Icon(Icons.delete_outline_rounded,
                      color: _kAccentRed, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — USERS
// ═══════════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _kNavyMid,
          padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 12, 16, 14),
          child: const Row(
            children: [
              Text('អ្នកប្រើប្រាស់',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: _kTextPrimary)),
            ],
          ),
        ),
        const Expanded(child: UserListScreen()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — CHAT
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return const AdminChatListScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsTab extends StatelessWidget {
  final dynamic user;
  const _SettingsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: _kNavyMid,
            padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 12, 16, 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: user?.profileImageUrl != null &&
                              user!.profileImageUrl!.isNotEmpty
                          ? null
                          : const LinearGradient(
                        colors: [_kAccentBlue, _kAccentCyan],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16)),
                    child: user?.profileImageUrl != null &&
                            user!.profileImageUrl!.isNotEmpty
                        ? Image.memory(
                            base64Decode(user.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              user?.fullName?.isNotEmpty == true
                                  ? user!.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w800)),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Administrator',
                      style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: _kTextPrimary)),
                    const SizedBox(height: 2),
                    Text(user?.roleDisplayName ?? 'Administrator',
                      style: const TextStyle(fontSize: 12, color: _kAccentBlue)),
                    Text(user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsSection(title: 'គណនី', items: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'ព័ត៌មានផ្ទាល់ខ្លួន',
                  subtitle: 'ឈ្មោះ · ទូរស័ព្ទ · អាសយដ្ឋាន',
                  color: _kAccentBlue,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<AuthProvider>().refreshProfile();
                    }
                  }),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'ពាក្យសម្ងាត់',
                  subtitle: 'ផ្លាស់ប្ដូរពាក្យសម្ងាត់',
                  color: _kAccentPurple,
                  onTap: () => _showChangePasswordSheet(context, user?.email ?? ''),
                ),
              ]),

              const SizedBox(height: 16),

              _SettingsSection(title: 'ប្រព័ន្ធ', items: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'ការជូនដំណឹង',
                  subtitle: 'គ្រប់គ្រងការជូនដំណឹង',
                  color: _kAccentAmber,
                  onTap: () => _showInfoDialog(context,
                    icon: Icons.notifications_rounded, color: _kAccentAmber,
                    title: 'ការជូនដំណឹង',
                    message: 'ការជូនដំណឹងសម្រាប់ការស្នើសុំថ្មី និងសារសន្ទនា ត្រូវបានបើកជានិច្ច។'),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  label: 'ភាសា',
                  subtitle: 'ភាសាខ្មែរ',
                  color: _kAccentCyan,
                  onTap: () => _showInfoDialog(context,
                    icon: Icons.language_rounded, color: _kAccentCyan,
                    title: 'ភាសា',
                    message: 'កម្មវិធីនេះប្រើភាសាខ្មែរទាំងស្រុងបច្ចុប្បន្ន។'),
                ),
                _SettingsTile(
                  icon: Icons.security_outlined,
                  label: 'ការសន្តិសុខ',
                  subtitle: 'Firestore rules · Access control',
                  color: _kAccentGreen,
                  onTap: () => _showInfoDialog(context,
                    icon: Icons.security_rounded, color: _kAccentGreen,
                    title: 'ការសន្តិសុខ',
                    message: 'គណនីអ្នកគ្រប់គ្រងត្រូវបានកំណត់ដោយប្រព័ន្ធ។ ច្បាប់ Firestore ការពារទិន្នន័យ។'),
                ),
              ]),

              const SizedBox(height: 16),

              _SettingsSection(title: 'ផ្សេងៗ', items: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'អំពីកម្មវិធី',
                  subtitle: 'Dorne v1.0.0 · Built with Flutter',
                  color: _kTextSecondary,
                  onTap: () => _showInfoDialog(context,
                    icon: Icons.info_rounded, color: _kTextSecondary,
                    title: 'អំពីកម្មវិធី',
                    message: 'តោះជួល (Dorne) — ប្រព័ន្ធភ្ជាប់កសិករ និងអ្នកផ្តល់សេវាកសិកម្ម។\n\nកំណែ៖ 1.0.0\nបង្កើតឡើងជាមួយ Flutter & Firebase.'),
                ),
              ]),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (_) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _kAccentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kAccentRed.withOpacity(0.3))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: _kAccentRed, size: 20),
                      SizedBox(width: 10),
                      Text('ចេញពីគណនី',
                        style: TextStyle(
                          color: _kAccentRed, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, {required IconData icon, required Color color,
      required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
            style: const TextStyle(color: _kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Text(message,
          style: const TextStyle(color: _kTextSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('យល់ព្រម', style: TextStyle(color: _kAccentBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, String email) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true, obscure2 = true;
    bool submitting = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ផ្លាស់ប្ដូរពាក្យសម្ងាត់',
                  style: TextStyle(color: _kTextPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('សម្រាប់គណនី $email',
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscure1,
                  style: const TextStyle(color: _kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'ពាក្យសម្ងាត់ថ្មី (យ៉ាងហោចណាស់ ៦ តួ)',
                    hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
                    filled: true, fillColor: _kNavyMid,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kBorder)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _kTextMuted, size: 18),
                      onPressed: () => setSheetState(() => obscure1 = !obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscure2,
                  style: const TextStyle(color: _kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
                    hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
                    filled: true, fillColor: _kNavyMid,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kBorder)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _kTextMuted, size: 18),
                      onPressed: () => setSheetState(() => obscure2 = !obscure2),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(errorText!, style: const TextStyle(color: _kAccentRed, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: submitting ? null : () async {
                      final p1 = newPassCtrl.text;
                      final p2 = confirmCtrl.text;
                      if (p1.length < 6) { setSheetState(() => errorText = 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួ'); return; }
                      if (p1 != p2) { setSheetState(() => errorText = 'ពាក្យសម្ងាត់មិនដូចគ្នា'); return; }
                      setSheetState(() { submitting = true; errorText = null; });
                      try {
                        await FirebaseAuth.instance.currentUser?.updatePassword(p1);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ផ្លាស់ប្ដូរពាក្យសម្ងាត់ដោយជោគជ័យ ✓'),
                              backgroundColor: _kAccentGreen));
                        }
                      } on FirebaseAuthException catch (e) {
                        String msg;
                        switch (e.code) {
                          case 'requires-recent-login': msg = 'សូមចេញ ហើយចូលគណនីម្ដងទៀត'; break;
                          case 'weak-password': msg = 'ពាក្យសម្ងាត់ខ្សោយពេក'; break;
                          default: msg = 'មានបញ្ហា (${e.code})';
                        }
                        setSheetState(() { submitting = false; errorText = msg; });
                      } catch (e) {
                        setSheetState(() { submitting = false; errorText = 'មានបញ្ហា: $e'; });
                      }
                    },
                    child: submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('រក្សាទុក', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: _kTextMuted, letterSpacing: 1.2)),
      ),
      Container(
        decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder)),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast) const Divider(height: 1, color: _kBorder, indent: 54),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label,
    required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kTextMuted, size: 18),
        ],
      ),
    ),
  );
}

// ─── Shared section title ─────────────────────────────────────────────────────

Widget _sectionTitle(String text) => Text(text,
  style: const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, color: _kTextPrimary));