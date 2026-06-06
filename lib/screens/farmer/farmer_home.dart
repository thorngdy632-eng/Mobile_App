import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _currentIndex = 0;

  final List<_ServiceCategory> _categories = const [
    _ServiceCategory(icon: '🚜', label: 'ត្រាក់ទ័រ', count: '១៥'),
    _ServiceCategory(icon: '🌾', label: 'ច្រូតស្រូវ', count: '៨'),
    _ServiceCategory(icon: '🛸', label: 'ដ្រូន', count: '៥'),
    _ServiceCategory(icon: '🛠', label: 'គោយន្ត', count: '១២'),
    _ServiceCategory(icon: '💨', label: 'បាញ់ថ្នាំ', count: '៧'),
  ];

  final List<_NearbyService> _nearbyServices = const [
    _NearbyService(
      name: 'សុខ វិចិត្រ',
      service: 'ត្រាក់ទ័រភ្ជួរស្រែ',
      distance: '២.៥ គម',
      rating: 4.8,
      price: '\$២៥/ហិចតា',
      emoji: '🚜',
    ),
    _NearbyService(
      name: 'ចាន់ សុភ័ណ្ឌ',
      service: 'គោយន្តដឹកស្រូវ',
      distance: '៣.១ គម',
      rating: 4.6,
      price: '\$១៥/តង់',
      emoji: '🛻',
    ),
    _NearbyService(
      name: 'រិទ្ធី កុសល',
      service: 'ម៉ាស៊ីនបាញ់ថ្នាំ',
      distance: '៤.០ គម',
      rating: 4.9,
      price: '\$១០/ហិចតា',
      emoji: '💨',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('កសិករ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ចេញ',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 0 ? _buildHome(user) : _buildProfile(),
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'ប្រវត្តិរូប',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
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
                  child: const Text('👨‍🌾', style: TextStyle(fontSize: 28)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        cat.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Nearby services
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'សេវាកម្មជិតអ្នក',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'មើលទាំងអស់',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_nearbyServices.map((s) => _buildServiceCard(s))),
        ],
      ),
    );
  }

  Widget _buildServiceCard(_NearbyService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(service.emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.service,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentGold),
                    const SizedBox(width: 2),
                    Text(
                      '${service.rating}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      service.distance,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                service.price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ទំនាក់ទំនង',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.farmerGreen.withOpacity(0.15),
            child: const Text('👨‍🌾', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user?.fullName ?? 'កសិករ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Center(
          child: Text(
            user?.email ?? '',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
        _buildProfileTile(Icons.phone_outlined, 'ទូរស័ព្ទ', user?.phoneNumber ?? '-'),
        _buildProfileTile(Icons.location_on_outlined, 'អាសយដ្ឋាន', user?.address ?? '-'),
        _buildProfileTile(Icons.calendar_today_outlined, 'ថ្ងៃចុះឈ្មោះ', 'មិនទាន់មាន'),
      ],
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.farmerGreen, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategory {
  final String icon;
  final String label;
  final String count;
  const _ServiceCategory({required this.icon, required this.label, required this.count});
}

class _NearbyService {
  final String name;
  final String service;
  final String distance;
  final double rating;
  final String price;
  final String emoji;
  const _NearbyService({
    required this.name,
    required this.service,
    required this.distance,
    required this.rating,
    required this.price,
    required this.emoji,
  });
}
