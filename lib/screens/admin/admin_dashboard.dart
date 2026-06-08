import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../chat/admin_chat_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'user_list_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kNavyDeep    = Color(0xFF0A1628);
const _kNavyMid     = Color(0xFF0F2040);
const _kNavySurface = Color(0xFF162237);
const _kAccentBlue  = Color(0xFF3B82F6);
const _kAccentCyan  = Color(0xFF06B6D4);
const _kAccentGreen = Color(0xFF10B981);
const _kAccentAmber = Color(0xFFF59E0B);
const _kAccentRed   = Color(0xFFEF4444);
const _kAccentPurple= Color(0xFF8B5CF6);
const _kSurface     = Color(0xFF1E2D45);
const _kSurfaceHi   = Color(0xFF243350);
const _kBorder      = Color(0xFF2A3F5F);
const _kTextPrimary = Color(0xFFF1F5F9);
const _kTextSecondary = Color(0xFF94A3B8);
const _kTextMuted   = Color(0xFF64748B);

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
    final myUid = user?.uid ?? '';

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

  // ── Body router ────────────────────────────────────────────────────────────

  Widget _buildBody(dynamic user) {
    switch (_currentIndex) {
      case 0: return _DashboardTab(user: user, onSwitchTab: _switchTab);
      case 1: return const _JobsTab();
      case 2: return const _UsersTab();
      case 3: return const _ChatTab();
      case 4: return _SettingsTab(user: user);
      default: return const SizedBox();
    }
  }

  // ── Bottom navigation ──────────────────────────────────────────────────────

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
                  _NavItem(icon: Icons.dashboard_rounded,     label: 'ផ្ទាំងគ្រប់គ្រង', index: 0, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.assignment_rounded,    label: 'ការស្នើសុំ',   index: 1, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.people_alt_rounded,    label: 'អ្នកប្រើ',    index: 2, current: _currentIndex, onTap: _switchTab),
                  _NavItem(icon: Icons.chat_rounded,          label: 'ការសន្ទនា',   index: 3, current: _currentIndex, onTap: _switchTab, badge: unread),
                  _NavItem(icon: Icons.settings_rounded,      label: 'ការកំណត់',   index: 4, current: _currentIndex, onTap: _switchTab),
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
        final myUid = context.read<AuthProvider>().currentUser?.uid ?? '';
        final totalJobs = appProv.tractorJobs.length + appProv.droneJobs.length;
        final pending = appProv.pendingTractorJobs.length + appProv.pendingDroneJobs.length;
        final confirmed = appProv.tractorJobs.where((j) => j.status == 'confirmed').length
            + appProv.droneJobs.where((j) => j.status == 'confirmed').length;
        final completed = appProv.tractorJobs.where((j) => j.status == 'completed').length
            + appProv.droneJobs.where((j) => j.status == 'completed').length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero header ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, myUid, chatProv)),

            // ── KPI cards ──────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _sectionTitle('ទិដ្ឋភាពសង្ខេប'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '$totalJobs', label: 'ការស្នើសុំសរុប', icon: Icons.assignment_rounded, color: _kAccentBlue)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '$pending', label: 'រង់ចាំ', icon: Icons.hourglass_top_rounded, color: _kAccentAmber)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _KpiCard(value: '$confirmed', label: 'បានបញ្ជាក់', icon: Icons.check_circle_rounded, color: _kAccentGreen)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(value: '$completed', label: 'បានបញ្ចប់', icon: Icons.task_alt_rounded, color: _kAccentCyan)),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Quick actions ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('ដំណើរការរហ័ស'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _QuickAction(icon: Icons.assignment_late_rounded, label: 'ការស្នើសុំ\nរង់ចាំ', color: _kAccentAmber, count: pending, onTap: () => onSwitchTab(1)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.people_alt_rounded,      label: 'អ្នកប្រើ\nប្រាស់',  color: _kAccentPurple, onTap: () => onSwitchTab(2)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.chat_rounded,            label: 'ការ\nសន្ទនា',    color: _kAccentCyan,   onTap: () => onSwitchTab(3)),
                      const SizedBox(width: 10),
                      _QuickAction(icon: Icons.bar_chart_rounded,       label: 'ស្ថិតិ\nព័ត៌មាន',  color: _kAccentGreen,  onTap: () {}),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Service breakdown ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('ការបែងចែកសេវាកម្ម'),
                    const SizedBox(height: 12),
                    _ServiceBreakdownCard(appProv: appProv),
                  ],
                ),
              ),
            ),

            // ── Pending jobs ───────────────────────────────────────────────
            if (pending > 0) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('ការស្នើសុំរង់ចាំ'),
                      GestureDetector(
                        onTap: () => onSwitchTab(1),
                        child: const Text('មើលទាំងអស់ →',
                          style: TextStyle(fontSize: 12, color: _kAccentBlue)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tractorPending = appProv.pendingTractorJobs;
                      final dronePending = appProv.pendingDroneJobs;
                      final all = [
                        ...tractorPending.map((j) => _PendingJobItem(
                          emoji: '🚜', title: j.serviceType, farmer: j.farmerName,
                          location: j.location, date: j.scheduledDate,
                          area: j.areaHectares, type: 'tractor', id: j.id,
                          appProv: appProv,
                        )),
                        ...dronePending.map((j) => _PendingJobItem(
                          emoji: '🛸', title: '${j.cropType} — ${j.pesticide}', farmer: j.farmerName,
                          location: j.location, date: j.scheduledDate,
                          area: j.areaHectares, type: 'drone', id: j.id,
                          appProv: appProv,
                        )),
                      ];
                      if (i >= all.length) return null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: all[i],
                      );
                    },
                    childCount: appProv.pendingTractorJobs.length + appProv.pendingDroneJobs.length,
                  ),
                ),
              ),
            ],

            // ── Activity log ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('សកម្មភាពចុងក្រោយ'),
                    const SizedBox(height: 12),
                    _ActivityLogCard(appProv: appProv),
                  ],
                ),
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
              // Avatar
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
              // Notification bell
              StreamBuilder<int>(
                stream: chatProv.totalUnreadStream(myUid),
                builder: (ctx, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderIconBtn(
                        icon: Icons.notifications_rounded,
                        onTap: () {},
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

          // Status bar — admin system status
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

// ─── Service breakdown card ───────────────────────────────────────────────────

class _ServiceBreakdownCard extends StatelessWidget {
  final AppProvider appProv;
  const _ServiceBreakdownCard({required this.appProv});

  @override
  Widget build(BuildContext context) {
    final tractor = appProv.tractorJobs.length;
    final drone = appProv.droneJobs.length;
    final total = tractor + drone;
    final tractorPct = total == 0 ? 0.0 : tractor / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _BreakdownItem(
                emoji: '🚜', label: 'ត្រាក់ទ័រ', count: tractor,
                color: _kAccentGreen, pct: tractorPct)),
              Container(width: 1, height: 40, color: _kBorder),
              Expanded(child: _BreakdownItem(
                emoji: '🛸', label: 'ដ្រូន', count: drone,
                color: _kAccentCyan, pct: 1 - tractorPct)),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Flexible(
                  flex: (tractorPct * 100).round().clamp(1, 99),
                  child: Container(height: 8, color: _kAccentGreen),
                ),
                Flexible(
                  flex: ((1 - tractorPct) * 100).round().clamp(1, 99),
                  child: Container(height: 8, color: _kAccentCyan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                  color: _kAccentGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text('ត្រាក់ទ័រ ${(tractorPct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, color: _kTextSecondary)),
              ]),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                  color: _kAccentCyan, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text('ដ្រូន ${((1-tractorPct) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, color: _kTextSecondary)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String emoji, label;
  final int count;
  final Color color;
  final double pct;

  const _BreakdownItem({required this.emoji, required this.label,
    required this.count, required this.color, required this.pct});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 4),
      Text('$count', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
    ],
  );
}

// ─── Pending job item ─────────────────────────────────────────────────────────

class _PendingJobItem extends StatelessWidget {
  final String emoji, title, farmer, location, date, type, id;
  final double area;
  final AppProvider appProv;

  const _PendingJobItem({
    required this.emoji, required this.title, required this.farmer,
    required this.location, required this.date, required this.area,
    required this.type, required this.id, required this.appProv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccentAmber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kAccentAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                    const SizedBox(height: 2),
                    Text(farmer,
                      style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _kAccentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccentAmber.withOpacity(0.4))),
                child: const Text('រង់ចាំ',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _kAccentAmber)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13, color: _kTextMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(location,
              style: const TextStyle(fontSize: 11, color: _kTextSecondary))),
            const Icon(Icons.calendar_today_outlined, size: 13, color: _kTextMuted),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
            const SizedBox(width: 8),
            const Icon(Icons.crop_square_outlined, size: 13, color: _kTextMuted),
            const SizedBox(width: 4),
            Text('$area ហិចតា',
              style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'បោះបង់', color: _kAccentRed,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (type == 'tractor') appProv.updateTractorJobStatus(id, 'cancelled');
                  else appProv.updateDroneJobStatus(id, 'cancelled');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'បញ្ជាក់ ✓', color: _kAccentGreen, filled: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (type == 'tractor') appProv.updateTractorJobStatus(id, 'confirmed');
                  else appProv.updateDroneJobStatus(id, 'confirmed');
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color,
    required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(filled ? 0 : 0.4)),
      ),
      child: Center(
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color)),
      ),
    ),
  );
}

// ─── Activity log card ────────────────────────────────────────────────────────

class _ActivityLogCard extends StatelessWidget {
  final AppProvider appProv;
  const _ActivityLogCard({required this.appProv});

  @override
  Widget build(BuildContext context) {
    // Build a combined sorted list of recent activity from jobs
    final allTractor = appProv.tractorJobs;
    final allDrone   = appProv.droneJobs;

    // Show last 5 confirmed/cancelled/completed actions
    final recent = [
      ...allTractor.where((j) => j.status != 'pending')
          .map((j) => _ActivityEntry(
            emoji: '🚜', title: '${j.serviceType} — ${j.farmerName}',
            status: j.status, time: j.createdAt)),
      ...allDrone.where((j) => j.status != 'pending')
          .map((j) => _ActivityEntry(
            emoji: '🛸', title: '${j.cropType} — ${j.farmerName}',
            status: j.status, time: j.createdAt)),
    ]..sort((a, b) => b.time.compareTo(a.time));

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
        child: const Center(
          child: Text('មិនទាន់មានសកម្មភាព',
            style: TextStyle(color: _kTextMuted, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _kSurface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
      child: Column(
        children: recent.take(5).toList().asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final isLast = i == (recent.length > 5 ? 4 : recent.length - 1);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Text(entry.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _kTextPrimary)),
                          const SizedBox(height: 2),
                          Text(_timeAgo(entry.time),
                            style: const TextStyle(
                              fontSize: 10, color: _kTextMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(status: entry.status),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: _kBorder, indent: 46),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} នាទីមុន';
    if (diff.inHours < 24)   return '${diff.inHours} ម៉ោងមុន';
    return '${diff.inDays} ថ្ងៃមុន';
  }
}

class _ActivityEntry {
  final String emoji, title, status;
  final DateTime time;
  const _ActivityEntry({required this.emoji, required this.title,
    required this.status, required this.time});
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
// TAB 1 — JOBS
// ═══════════════════════════════════════════════════════════════════════════════

class _JobsTab extends StatefulWidget {
  const _JobsTab();
  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _filter = 'all'; // all | pending | confirmed | completed | cancelled

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, appProv, _) {
      return Column(
        children: [
          // Header
          Container(
            color: _kNavyMid,
            padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ការស្នើសុំ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: _kTextPrimary)),
                const SizedBox(height: 12),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all','pending','confirmed','completed','cancelled']
                        .map((s) => _FilterChip(
                          label: _filterLabel(s), value: s,
                          selected: _filter == s,
                          onTap: () => setState(() => _filter = s),
                        ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: _kAccentBlue,
                  unselectedLabelColor: _kTextMuted,
                  indicatorColor: _kAccentBlue,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: _kBorder,
                  tabs: const [
                    Tab(text: '🚜  ត្រាក់ទ័រ'),
                    Tab(text: '🛸  ដ្រូន'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _JobList(
                  jobs: _filtered(appProv.tractorJobs),
                  type: 'tractor', appProv: appProv),
                _JobList(
                  jobs: _filtered(appProv.droneJobs),
                  type: 'drone', appProv: appProv),
              ],
            ),
          ),
        ],
      );
    });
  }

  List _filtered(List jobs) {
    if (_filter == 'all') return jobs;
    return jobs.where((j) => j.status == _filter).toList();
  }

  String _filterLabel(String s) {
    switch (s) {
      case 'all': return 'ទាំងអស់';
      case 'pending': return 'រង់ចាំ';
      case 'confirmed': return 'បញ្ជាក់';
      case 'completed': return 'បញ្ចប់';
      case 'cancelled': return 'បោះបង់';
      default: return s;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _kAccentBlue : _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _kAccentBlue : _kBorder)),
      child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _kTextSecondary)),
    ),
  );
}

class _JobList extends StatelessWidget {
  final List jobs;
  final String type;
  final AppProvider appProv;

  const _JobList({required this.jobs, required this.type, required this.appProv});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('មិនមានការស្នើសុំ',
              style: TextStyle(color: _kTextMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (ctx, i) {
        final job = jobs[i];
        final isTractor = type == 'tractor';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isTractor ? '🚜' : '🛸',
                      style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isTractor ? job.serviceType
                              : '${job.cropType} — ${job.pesticide}',
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: _kTextPrimary)),
                          Text(job.farmerName,
                            style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary)),
                        ],
                      ),
                    ),
                    _StatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 16, runSpacing: 4, children: [
                  _InfoPill(icon: Icons.location_on_outlined, text: job.location),
                  _InfoPill(icon: Icons.calendar_today_outlined,
                    text: '${job.scheduledDate} ${job.scheduledTime}'),
                  _InfoPill(icon: Icons.crop_square_outlined,
                    text: '${job.areaHectares} ហិចតា'),
                ]),
                if (job.notes != null && job.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoPill(icon: Icons.notes_outlined, text: job.notes!),
                ],
                if (job.status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'បោះបង់', color: _kAccentRed,
                        onTap: () => isTractor
                          ? appProv.updateTractorJobStatus(job.id, 'cancelled')
                          : appProv.updateDroneJobStatus(job.id, 'cancelled'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'បញ្ជាក់ ✓', color: _kAccentGreen, filled: true,
                        onTap: () => isTractor
                          ? appProv.updateTractorJobStatus(job.id, 'confirmed')
                          : appProv.updateDroneJobStatus(job.id, 'confirmed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'បញ្ចប់', color: _kAccentBlue, filled: true,
                        onTap: () => isTractor
                          ? appProv.updateTractorJobStatus(job.id, 'completed')
                          : appProv.updateDroneJobStatus(job.id, 'completed'),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: _kTextMuted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — USERS (wraps existing UserListScreen with dark theming override)
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
// TAB 3 — CHAT (wraps existing AdminChatListScreen)
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
                      style: TextStyle(fontSize: 12, color: _kAccentBlue)),
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
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 16),

              _SettingsSection(title: 'ប្រព័ន្ធ', items: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'ការជូនដំណឹង',
                  subtitle: 'គ្រប់គ្រងការជូនដំណឹង',
                  color: _kAccentAmber,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  label: 'ភាសា',
                  subtitle: 'ភាសាខ្មែរ',
                  color: _kAccentCyan,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.security_outlined,
                  label: 'ការសន្តិសុខ',
                  subtitle: 'Firestore rules · Access control',
                  color: _kAccentGreen,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 16),

              _SettingsSection(title: 'ផ្សេងៗ', items: [
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  label: 'ជំនួយ',
                  subtitle: 'FAQ · Support',
                  color: _kTextSecondary,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'អំពីកម្មវិធី',
                  subtitle: 'Dorne v1.0.0 · Built with Flutter',
                  color: _kTextSecondary,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 24),

              // Logout
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await auth.logout();
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
                if (!isLast)
                  const Divider(height: 1, color: _kBorder, indent: 54),
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
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _kTextPrimary)),
                Text(subtitle,
                  style: const TextStyle(
                    fontSize: 11, color: _kTextSecondary)),
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