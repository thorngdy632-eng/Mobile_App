// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_Notification> _items = [
    _Notification(
      icon: Icons.check_circle_outline,
      iconColor: AppColors.green,
      title: 'ការងារត្រូវបានបញ្ជាក់',
      body: 'ការងារ គោយន្តដឹកស្រូវ នៅ ស្រុកស្វាយចេក ត្រូវបានបញ្ជាក់',
      time: '10 នាទីមុន',
    ),
    _Notification(
      icon: Icons.local_shipping_outlined,
      iconColor: AppColors.primaryMid,
      title: 'ការដឹកថ្មី',
      body: 'មានការដឹកថ្មី: ជីពី ក្រុងសិរីសោភ័ណ ទៅ ស្រុកមង្គលបូរី (\$80)',
      time: '30 នាទីមុន',
    ),
    _Notification(
      icon: Icons.info_outline,
      iconColor: AppColors.amber,
      title: 'ការរំលឹក',
      body: 'ការងាររបស់អ្នកស្អែក ព្រឹក ៦:៣០ — ភ្ជួរស្រែ',
      time: '១ ម៉ោងមុន',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ការជូនដំណឹង'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = _items[i];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: n.iconColor.withOpacity(0.12),
                child: Icon(n.icon, color: n.iconColor),
              ),
              title: Text(
                n.title,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n.body, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    n.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Notification {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;

  const _Notification({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
  });
}
