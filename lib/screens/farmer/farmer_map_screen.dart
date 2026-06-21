// lib/screens/farmer/farmer_map_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'service_request_map_screen.dart';

class _ImgCfg {
  final String imagePath;
  final Color bg;
  final Color iconColor;
  const _ImgCfg(this.imagePath, this.bg, this.iconColor);
}

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png', Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'harvesting':  _ImgCfg('assets/images/2.png', Color(0xFFFFF8E1), Color(0xFFF9A825)),
  'transport':   _ImgCfg('assets/images/3.png', Color(0xFFE8F5E9), Color(0xFF43A047)),
  'irrigation':  _ImgCfg('assets/images/4.png', Color(0xFFE3F2FD), Color(0xFF1E88E5)),
  'drone_spray': _ImgCfg('assets/images/5.png', Color(0xFFFFEBEE), Color(0xFFEF5350)),
};

/// Map tab for the Farmer role.  Shows the farmer's real-time GPS location
/// as a profile-avatar marker and colour-coded service-request pins.
/// Farmers can drop a pin at their current location and submit a service request.
class FarmerMapScreen extends StatefulWidget {
  const FarmerMapScreen({super.key});

  @override
  State<FarmerMapScreen> createState() => _FarmerMapScreenState();
}

class _FarmerMapScreenState extends State<FarmerMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(11.5564, 104.9282);
  LatLng? _dropped;
  bool _locating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _locationError = 'មិនអាចទាញយកទីតាំងបានទេ';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = here;
        _locating = false;
      });
      _mapController.move(here, 15);
    } catch (_) {
      setState(() {
        _locating = false;
        _locationError = 'មិនអាចទាញយកទីតាំងបានទេ';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF9A825);
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'completed':
        return const Color(0xFF1565C0);
      case 'declined':
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _buildAvatar(AuthProvider auth) {
    final url = auth.currentUser?.profileImageUrl;
    if (url != null && url.isNotEmpty) {
      try {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: MemoryImage(base64Decode(url)),
          ),
        );
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _dropped = point);
  }

  void _openServicePicker() {
    if (_dropped == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ជ្រើសរើសប្រភេទសេវា',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ServiceTypes.all.length,
                  itemBuilder: (context, i) {
                    final svc = ServiceTypes.all[i];
                    final cfg = _serviceImgCfgs[svc['id'] as String];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cfg?.bg ?? Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: cfg != null
                            ? Image.asset(cfg.imagePath, fit: BoxFit.contain)
                            : Icon(Icons.build, color: Colors.grey),
                      ),
                      title: Text(svc['label'] as String),
                      subtitle: Text(svc['subtitle'] as String,
                          style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceRequestMapScreen(
                              serviceType: svc['id'] as String,
                              initialLocation: _dropped,
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    final myRequests = app.serviceRequestsForFarmer(myUid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ទីតាំងបច្ចុប្បន្ន'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'ទីតាំងបច្ចុប្បន្ន',
            onPressed: () {
              _detectLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.letsrent.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: _buildAvatar(auth),
                  ),
                  for (final r in myRequests)
                    Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 50,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showRequestSheet(r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(r.status),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ServiceTypes.labelOf(r.serviceType),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _statusColor(r.status), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _serviceImgCfgs[r.serviceType]?.imagePath ??
                                      'assets/images/app_icon.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    ServiceTypes.infoOf(r.serviceType)['icon']
                                        as IconData,
                                    color: _statusColor(r.status),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_dropped != null)
                    Marker(
                      point: _dropped!,
                      width: 48,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/location.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 10,
                            color: AppColors.primaryGreen,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_locating)
            const Positioned(
              top: 12,
              left: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('កំពុងស្វែងរកទីតាំង...',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          if (_locationError != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_locationError!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(const Color(0xFFF9A825), 'កំពុងរង់ចាំ'),
                    _legendItem(const Color(0xFF2E7D32), 'បានទទួល'),
                    _legendItem(const Color(0xFF1565C0), 'បញ្ចប់'),
                    _legendItem(const Color(0xFFD32F2F), 'បដិសេធ'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'refresh',
            backgroundColor: Colors.white,
            onPressed: _detectLocation,
            child: const Icon(Icons.refresh, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'share',
            backgroundColor: AppColors.primaryGreen,
            onPressed: () async {
              await _detectLocation();
              if (!_locating) {
                setState(() => _dropped = _center);
                _mapController.move(_center, 16);

                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('locations').add({
                    'latitude': _center.latitude,
                    'longitude': _center.longitude,
                    'userId': user.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                if (mounted) _openServicePicker();
              }
            },
            icon: const Icon(Icons.share_location, color: Colors.white),
            label: const Text('ចែករំលែកទីតាំង',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _showRequestSheet(ServiceRequest r) {
    final info = ServiceTypes.infoOf(r.serviceType);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _serviceImgCfgs[r.serviceType]?.imagePath ?? 'assets/images/app_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(info['icon'] as IconData, color: info['color'] as Color, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ServiceTypes.labelOf(r.serviceType),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(r.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.person, 'ឈ្មោះ', r.farmerName),
            _infoRow(Icons.location_on, 'ទីតាំង', r.currentAddress),
            _infoRow(Icons.crop_square, 'ទំហំដី', '${r.landArea} ${r.landUnit == 'rai' ? 'រ៉ៃ' : 'ហេកតា'}'),
            _infoRow(Icons.attach_money, 'តម្លៃ', '${r.offerPrice.toStringAsFixed(0)} រៀល'),
            if (r.providerName != null)
              _infoRow(Icons.engineering, 'អ្នកផ្តល់សេវា', r.providerName!),
            if (r.notes != null && r.notes!.isNotEmpty)
              _infoRow(Icons.note, 'ចំណាំ', r.notes!),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
