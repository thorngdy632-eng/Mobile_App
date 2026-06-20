// lib/screens/provider/incoming_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import 'request_detail_screen.dart';

/// Service Provider screen: shows every pending [ServiceRequest] whose
/// `serviceType` matches this provider's `UserModel.serviceType`.
///
/// Each card shows the farmer's name, dropped location, land size, offered
/// price, and the distance from the provider's current GPS position. Tapping
/// a card opens [RequestDetailScreen] where the provider can see the map,
/// accept or decline, and contact the farmer.
class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  Position? _myPosition;

  @override
  void initState() {
    super.initState();
    _loadMyPosition();
  }

  Future<void> _loadMyPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {
      // Distance simply won't be shown if location is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;

    final myServiceType = user?.serviceType ?? ServiceTypes.plowing;
    final requests = app
        .pendingServiceRequestsForProvider(
          myServiceType,
          excludeDeclinedBy: user?.uid,
        )
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final info = ServiceTypes.infoOf(myServiceType);

    return Scaffold(
      appBar: AppBar(
        title: Text('សំណើថ្មី — ${info['label']}'),
        backgroundColor: info['color'] as Color,
        foregroundColor: Colors.white,
      ),
      body: requests.isEmpty
          ? const Center(child: Text('មិនទាន់មានសំណើថ្មីទេឥឡូវនេះ'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                double? distanceKm;
                if (_myPosition != null) {
                  distanceKm = app.distanceToRequestKm(
                    providerLat: _myPosition!.latitude,
                    providerLng: _myPosition!.longitude,
                    request: r,
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: info['color'] as Color,
                      child: const Icon(Icons.agriculture, color: Colors.white),
                    ),
                    title: Text(r.farmerName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ទីតាំង: ${r.currentAddress}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('ទំហំដី: ${r.landLabel}'),
                          Text(
                              'ផ្តល់តម្លៃ: ${r.offerPrice.toStringAsFixed(0)} រៀល'),
                          if (distanceKm != null)
                            Text(
                              'ចម្ងាយ: ${distanceKm.toStringAsFixed(1)} គម',
                              style: TextStyle(
                                  color: info['color'] as Color,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(
                            request: r,
                            providerPosition: _myPosition,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}