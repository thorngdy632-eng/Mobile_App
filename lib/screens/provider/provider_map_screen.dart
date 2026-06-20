// lib/screens/provider/provider_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_screen.dart';

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

/// Map tab for the Service Provider role.
///
/// Shows every [ServiceRequest] whose `serviceType` matches this provider's
/// own `UserModel.serviceType` as a live pin on the map — i.e. if a Farmer
/// drops a pin asking for "ភ្ជួរស្រែ", only providers registered for
/// "ភ្ជួរស្រែ" ever see that pin here. The list is driven straight off
/// AppProvider's real-time Firestore stream, so a new request appears the
/// instant the Farmer submits it — no refresh needed.
///
/// Tapping a pin opens a sheet with the farmer's details and:
///   • Accept / Decline buttons while the request is still pending. Accept
///     immediately opens a chat with that farmer.
///   • A "Message farmer" + "Mark completed" action once this provider has
///     accepted the job.
class ProviderMapScreen extends StatefulWidget {
  const ProviderMapScreen({super.key});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(11.5564, 104.9282); // Phnom Penh default
  Position? _myPosition;
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
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _locationError = 'មិនអាចទាញយកទីតាំងបានទេ';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myPosition = pos;
        _center = here;
        _locating = false;
      });
      _mapController.move(here, 14);
    } catch (_) {
      setState(() {
        _locating = false;
        _locationError = 'មិនអាចទាញយកទីតាំងបានទេ';
      });
    }
  }

  Color _pinColor(ServiceRequest r, String myUid) {
    if (r.status == 'accepted' && r.providerUid == myUid) {
      return const Color(0xFF2E7D32); // mine, accepted
    }
    return const Color(0xFFF9A825); // still pending
  }

  Widget _buildSelfMarker(AuthProvider auth) {
    final url = auth.currentUser?.profileImageUrl;
    ImageProvider? avatar;
    if (url != null && url.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(url));
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryGreen,
        backgroundImage: avatar,
        child: avatar == null
            ? const Icon(Icons.engineering, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    final myServiceType = auth.currentUser?.serviceType ?? ServiceTypes.plowing;
    final info = ServiceTypes.infoOf(myServiceType);
    final Color accent = info['color'] as Color;

    // Only requests matching MY service type, minus ones I've already
    // declined (those stay visible to every other matching provider), plus
    // the jobs I personally accepted so I can keep tracking/messaging them.
    final pending = app.pendingServiceRequestsForProvider(
      myServiceType,
      excludeDeclinedBy: myUid,
    );
    final mine = app.acceptedServiceRequestsForProvider(myUid);
    final visible = [...pending, ...mine];

    return Scaffold(
      appBar: AppBar(
        title: Text('ផែនទីសំណើ — ${info['label']}'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${pending.length} ថ្មី',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'ទីតាំងបច្ចុប្បន្ន',
            onPressed: _detectLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
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
                    child: _buildSelfMarker(auth),
                  ),
                  for (final r in visible)
                    Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 50,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showRequestSheet(context, r, myUid),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _pinColor(r, myUid),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.farmerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _pinColor(r, myUid), width: 2.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
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
                                    ServiceTypes.infoOf(r.serviceType)['icon'] as IconData,
                                    color: _pinColor(r, myUid),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('កំពុងស្វែងរកទីតាំង...', style: TextStyle(fontSize: 12)),
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
                      Expanded(child: Text(_locationError!, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
            ),
          if (visible.isEmpty && !_locating)
            Positioned(
              bottom: 90,
              left: 24,
              right: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'មិនទាន់មានសំណើសេវា "${info['label']}" នៅជិតអ្នកទេឥឡូវនេះ',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(const Color(0xFFF9A825), 'សំណើថ្មី — រង់ចាំចម្លើយ'),
                    _legendItem(const Color(0xFF2E7D32), 'អ្នកបានទទួល'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.white,
        onPressed: _detectLocation,
        child: const Icon(Icons.refresh, color: Colors.black87),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _showRequestSheet(BuildContext context, ServiceRequest r, String myUid) {
    showRequestDetailSheet(
      context: context,
      request: r,
      myUid: myUid,
      myPosition: _myPosition,
    );
  }
}

/// Public helper so other screens (e.g. the dashboard's "new job alerts")
/// can open the exact same farmer-detail / accept / decline / chat sheet
/// that the map uses, instead of duplicating that logic.
void showRequestDetailSheet({
  required BuildContext context,
  required ServiceRequest request,
  required String myUid,
  Position? myPosition,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _RequestSheet(
      request: request,
      myUid: myUid,
      myPosition: myPosition,
      parentContext: context,
    ),
  );
}

// ─── Bottom sheet: farmer details + Accept / Decline / Message ───────────────

class _RequestSheet extends StatefulWidget {
  final ServiceRequest request;
  final String myUid;
  final Position? myPosition;

  /// BuildContext of the screen underneath the sheet (ProviderMapScreen).
  /// We navigate/show snackbars through this instead of the sheet's own
  /// context, because the sheet's context stops being reliable the moment
  /// we pop it to open a chat screen.
  final BuildContext parentContext;

  const _RequestSheet({
    required this.request,
    required this.myUid,
    required this.myPosition,
    required this.parentContext,
  });

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  bool _busy = false;

  bool get _isMine =>
      widget.request.status == 'accepted' && widget.request.providerUid == widget.myUid;
  bool get _isPending => widget.request.status == 'pending';

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final info = ServiceTypes.infoOf(r.serviceType);
    final accent = info['color'] as Color;
    final app = context.read<AppProvider>();

    double? distanceKm;
    if (widget.myPosition != null) {
      distanceKm = app.distanceToRequestKm(
        providerLat: widget.myPosition!.latitude,
        providerLng: widget.myPosition!.longitude,
        request: r,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(info['icon'] as IconData, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.farmerName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: r.statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.statusLabel,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(info['label'] as String,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
          const SizedBox(height: 14),
          _infoRow(Icons.location_on, 'ទីតាំង', r.currentAddress),
          _infoRow(Icons.crop_square, 'ទំហំដី', r.landLabel),
          _infoRow(Icons.attach_money, 'តម្លៃដែលផ្តល់', '${r.offerPrice.toStringAsFixed(0)} រៀល'),
          if (distanceKm != null)
            _infoRow(Icons.social_distance, 'ចម្ងាយពីអ្នក', '${distanceKm.toStringAsFixed(1)} គម'),
          if (r.notes != null && r.notes!.isNotEmpty)
            _infoRow(Icons.note, 'ចំណាំ', r.notes!),
          const SizedBox(height: 18),
          if (_isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('បដិសេធ', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _busy ? null : () => _respond(accept: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('យល់ព្រមទទួលសេវា'),
                    onPressed: _busy ? null : () => _respond(accept: true),
                  ),
                ),
              ],
            )
          else if (_isMine)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('បានបញ្ចប់'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _busy ? null : _markCompleted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text('ផ្ញើសារ'),
                        onPressed: _openChat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.undo_rounded, color: Colors.orange),
                    label: const Text('បោះបង់សំណើ',
                        style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _busy ? null : _abandon,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _respond({required bool accept}) async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _busy = true);

    await app.respondToServiceRequest(
      requestId: widget.request.id,
      accept: accept,
      providerUid: user.uid,
      providerName: user.fullName,
    );

    final parent = widget.parentContext;
    if (mounted) Navigator.of(context).pop(); // close the sheet
    if (!parent.mounted) return;

    if (accept) {
      // Accepted — go straight into a chat with the farmer so the provider
      // can message them right away.
      await _openChatVia(parent, user.uid);
    } else {
      ScaffoldMessenger.of(parent).showSnackBar(
        const SnackBar(content: Text('អ្នកបានបដិសេធសំណើនេះ')),
      );
    }
  }

  Future<void> _markCompleted() async {
    final app = context.read<AppProvider>();
    setState(() => _busy = true);
    await app.updateServiceRequestStatus(widget.request.id, 'completed');

    final parent = widget.parentContext;
    if (mounted) Navigator.of(context).pop();
    if (!parent.mounted) return;
    ScaffoldMessenger.of(parent).showSnackBar(
      const SnackBar(content: Text('បានកំណត់ថាសេវានេះបានបញ្ចប់')),
    );
  }

  Future<void> _abandon() async {
    final app = context.read<AppProvider>();
    setState(() => _busy = true);
    await app.abandonServiceRequest(widget.request.id);

    final parent = widget.parentContext;
    if (mounted) Navigator.of(context).pop();
    if (!parent.mounted) return;
    ScaffoldMessenger.of(parent).showSnackBar(
      const SnackBar(content: Text('បានបោះបង់សំណើនេះ។ សំណើនឹងត្រឡប់ទៅជារង់ចាំវិញ')),
    );
  }

  Future<void> _openChat() async {
    final myUid = context.read<AuthProvider>().currentUser?.uid;
    if (myUid == null) return;
    final parent = widget.parentContext;
    Navigator.of(context).pop(); // close the sheet first
    if (!parent.mounted) return;
    await _openChatVia(parent, myUid);
  }

  Future<void> _openChatVia(BuildContext target, String myUid) async {
    final chat = target.read<ChatProvider>();
    final chatRoomId =
        await chat.ensureChatRoom(myUid: myUid, peerId: widget.request.farmerUid);
    if (!target.mounted) return;

    Navigator.of(target).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatRoomId,
          peerId: widget.request.farmerUid,
          peerName: widget.request.farmerName,
        ),
      ),
    );
  }
}