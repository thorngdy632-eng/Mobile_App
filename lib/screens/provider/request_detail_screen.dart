// lib/screens/provider/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';

/// Detail view for a single [ServiceRequest], shown to the matching Service
/// Provider. Displays the farmer's full request (name, place of birth,
/// dropped location, land area, offer price), a Flutter Map / OSM view with
/// markers for both the farmer's location and the provider's current
/// position plus the distance between them, and actions to Accept, Decline,
/// or Contact (chat) the farmer.
class RequestDetailScreen extends StatelessWidget {
  final ServiceRequest request;

  /// Provider's current GPS position, if available (passed from the list
  /// screen so we don't re-fetch it here).
  final Position? providerPosition;

  const RequestDetailScreen({
    super.key,
    required this.request,
    this.providerPosition,
  });

  @override
  Widget build(BuildContext context) {
    final info = ServiceTypes.infoOf(request.serviceType);
    final Color accent = info['color'] as Color;
    final farmerPoint = LatLng(request.latitude, request.longitude);

    final double? distanceKm = providerPosition != null
        ? context.read<AppProvider>().distanceToRequestKm(
              providerLat: providerPosition!.latitude,
              providerLng: providerPosition!.longitude,
              request: request,
            )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('សំណើពី ${request.farmerName}'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── ផែនទីបង្ហាញទីតាំងកសិករ និងអ្នកផ្តល់សេវា ──
          SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: farmerPoint,
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
                      point: farmerPoint,
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child:
                          Icon(Icons.location_on, color: accent, size: 42),
                    ),
                    if (providerPosition != null)
                      Marker(
                        point: LatLng(
                            providerPosition!.latitude, providerPosition!.longitude),
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.local_shipping,
                            color: Colors.blueGrey, size: 36),
                      ),
                  ],
                ),
                if (providerPosition != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(providerPosition!.latitude,
                              providerPosition!.longitude),
                          farmerPoint,
                        ],
                        strokeWidth: 3,
                        color: accent,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (distanceKm != null)
            Container(
              width: double.infinity,
              color: accent.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ចម្ងាយពីទីតាំងរបស់អ្នក: ${distanceKm.toStringAsFixed(1)} គីឡូម៉ែត្រ',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: accent),
              ),
            ),

          // ── ព័ត៌មានលម្អិតរបស់សំណើ ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailRow(icon: Icons.person, label: 'ឈ្មោះកសិករ', value: request.farmerName),
                _DetailRow(icon: Icons.home, label: 'ទីកន្លែងកំណើត', value: request.placeOfBirth.isEmpty ? '—' : request.placeOfBirth),
                _DetailRow(icon: Icons.location_on, label: 'ទីតាំងបច្ចុប្បន្ន', value: request.currentAddress),
                _DetailRow(icon: Icons.build, label: 'ប្រភេទសេវាត្រូវការ', value: info['label'] as String),
                _DetailRow(icon: Icons.crop_square, label: 'ទំហំដី', value: request.landLabel),
                _DetailRow(icon: Icons.attach_money, label: 'តម្លៃដែលផ្តល់', value: '${request.offerPrice.toStringAsFixed(0)} រៀល'),
                if (request.notes != null && request.notes!.isNotEmpty)
                  _DetailRow(icon: Icons.note_alt, label: 'ចំណាំ', value: request.notes!),
                const SizedBox(height: 8),
                Chip(
                  label: Text(request.statusLabel,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: request.statusColor,
                ),
              ],
            ),
          ),

          // ── សកម្មភាព ──
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: request.status == 'pending'
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('បដិសេធ',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => _respond(context, accept: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.check),
                            label: const Text('យល់ព្រមទទួលសេវា'),
                            onPressed: () => _respond(context, accept: true),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('ទាក់ទងកសិករ'),
                        onPressed: () => _openChat(context),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await app.respondToServiceRequest(
      requestId: request.id,
      accept: accept,
      providerUid: user.uid,
      providerName: user.fullName,
    );

    if (!context.mounted) return;

    if (accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('អ្នកបានទទួលយល់ព្រមជាមួយសំណើនេះ'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      // Open the request again in "accepted" mode so the provider can
      // immediately message the farmer.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(
            request: request.copyWith(
              status: 'accepted',
              providerUid: user.uid,
              providerName: user.fullName,
            ),
            providerPosition: providerPosition,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('អ្នកបានបដិសេធសំណើនេះ')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final myUid = auth.currentUser?.uid;
    if (myUid == null) return;

    final chatRoomId =
        await chat.ensureChatRoom(myUid: myUid, peerId: request.farmerUid);
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatRoomId,
          peerId: request.farmerUid,
          peerName: request.farmerName,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}