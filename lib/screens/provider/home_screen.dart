// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/job_card.dart';
import 'notifications/notifications_screen.dart';
import 'jobs/job_detail_screen.dart';
import 'jobs/all_jobs_screen.dart';
import 'widgets/drawer_menu.dart';
import 'equipment/equipment_detail_screen.dart';
import '../../models/equipment_item.dart';

// ─── Static data for sections not yet in the provider ────────────────────────

const List<_PromoItem> _promos = [
  _PromoItem(
    tag: 'ចំណេញ ១០០%',
    title: 'សហគមន៍ភូមិកំពង់ចំបក់ ១០០%\nតាមរយៈ Escrow',
    subtitle: 'ធ្វើការ · ABA · KHQR',
    accentColor: Color(0xFFFF7043),
  ),
  _PromoItem(
    tag: 'ថ្មី',
    title: 'ជួលត្រាក់ទ័រ Kubota\nតម្លៃពិសេសសម្រាប់ម្ចាស់ដំណាំ',
    subtitle: 'តុក្កតា · ABA',
    accentColor: Color(0xFF43A047),
  ),
];

final List<EquipmentItem> _equipment = [
  const EquipmentItem(
    name: 'គ្រឿង Kubota L3408',
    price: '180,000រៀល',
    location: 'ស្រុកបាទី',
    rating: 4.9,
    imageAsset: 'tractor', // 👈 ប្រើប្រាស់សម្រាប់រើសពណ៌ និងរូបភាពកាត
    badge: EquipmentBadge.none,
  ),
  const EquipmentItem(
    name: 'យន្តហោះ Yanmar YT3',
    price: '120,000រៀល',
    location: 'ក្រុងសិរីស្វាយប៉ាវ',
    rating: 4.7,
    imageAsset: 'harvester', // 👈 ប្រើប្រាស់សម្រាប់រើសពណ៌ និងរូបភាពកាត
    badge: EquipmentBadge.hot,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _promoPage = 0;
  final PageController _promoCtrl = PageController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildPromoBanner()),
            SliverToBoxAdapter(child: _buildScheduledJobs()),
            SliverToBoxAdapter(child: _buildSectionLabel(
              'ទំនិញពេញនិយម', 'ទាំងអស់ ›',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllJobsScreen())))),
            SliverToBoxAdapter(child: _buildEquipmentCards()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Consumer<AppProvider>(
      builder: (_, provider, __) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.fromLTRB(16, top + 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ស្វាគមន៍ មកដល់',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(height: 1),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ).then((_) => provider.clearNotifications()),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    if (provider.notificationCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                  text: 'សមាគមន៍កសិករខ្មែរ, ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3),
                ),
                TextSpan(
                  text: 'តោះជួល!',
                  style: TextStyle(
                      color: Color(0xFFA5D6A7),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF388E3C),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ស្វែងរកគ្រឿងចក្រ ឬ សេវាកម្មផ្សេងៗ...',
                style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSectionLabelInline('ការផ្សព្វផ្សាយពិសេស', 'ទាំងអស់ ›'),
          ),
          SizedBox(
            height: 130,
            child: PageView.builder(
              controller: _promoCtrl,
              itemCount: _promos.length,
              onPageChanged: (i) => setState(() => _promoPage = i),
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(
                    left: 16,
                    right: i == _promos.length - 1 ? 16 : 8),
                child: _PromoBannerCard(item: _promos[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promos.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _promoPage ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _promoPage
                      ? AppColors.primaryGreen
                      : const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledJobs() {
    return Consumer<AppProvider>(
      builder: (_, provider, __) => provider.isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()))
          : Column(
              children: provider.scheduledJobs
                  .map((job) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: JobCard(
                          job: job,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildEquipmentCards() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _equipment.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < _equipment.length - 1 ? 12 : 0),
          child: _EquipmentCard(
            item: _equipment[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EquipmentDetailScreen(item: _equipment[i])),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String action,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: _buildSectionLabelInline(title, action, onTap: onTap),
    );
  }

  Widget _buildSectionLabelInline(String title, String action,
      {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        GestureDetector(
          onTap: onTap,
          child: Text(action,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.primaryGreen)),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PromoItem {
  final String tag;
  final String title;
  final String subtitle;
  final Color accentColor;
  const _PromoItem(
      {required this.tag,
      required this.title,
      required this.subtitle,
      required this.accentColor});
}

class _PromoBannerCard extends StatelessWidget {
  final _PromoItem item;
  const _PromoBannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.accentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(item.tag,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 3,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(item.subtitle,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: item.accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final VoidCallback onTap;
  const _EquipmentCard({required this.item, required this.onTap});

  static const Map<String, _ImgCfg> _cfgs = {
    'tractor':   _ImgCfg('assets/images/3.png', Color(0xFFE8F5E9), Color(0xFF43A047)),
    'harvester': _ImgCfg('assets/images/2.png', Color(0xFFFFF8E1), Color(0xFFF9A825)),
    'pump':      _ImgCfg('assets/images/4.png', Color(0xFFE3F2FD), Color(0xFF1E88E5)),
    'koyon':     _ImgCfg('assets/images/1.png', Color(0xFFFFF3E0), Color(0xFFFF9800)),
    'spray':     _ImgCfg('assets/images/5.png', Color(0xFFFFEBEE), Color(0xFFEF5350)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgs[item.imageAsset] ??
        const _ImgCfg('assets/images/app_icon.png', Color(0xFFF5F5F5), Color(0xFF9E9E9E));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 105,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Image.asset(
                      cfg.imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: cfg.fg, size: 40),
                    ),
                  ),
                ),
                if (item.badge != EquipmentBadge.none)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.badge == EquipmentBadge.hot
                            ? AppColors.badgeHot
                            : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item.badge == EquipmentBadge.hot ? 'HOT' : 'ថ្មី',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.price,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.amber),
                          const SizedBox(width: 2),
                          Text(item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImgCfg {
  final String imagePath;
  final Color bg;
  final Color fg;
  const _ImgCfg(this.imagePath, this.bg, this.fg);
}