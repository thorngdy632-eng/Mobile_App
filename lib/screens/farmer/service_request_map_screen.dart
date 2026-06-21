// lib/screens/farmer/service_request_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

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

const _kGreen = Color(0xFF2E7D32);
const _kSurface = Color(0xFFF7F9F7);
const _kCard = Colors.white;

/// Farmer taps one of the 5 service tiles on the home screen → this screen
/// opens with a FlutterMap/OSM panel.  They tap the map to drop a pin, then
/// hit the bottom CTA to open the modern request form.
class ServiceRequestMapScreen extends StatefulWidget {
  final String serviceType;
  final LatLng? initialLocation;

  const ServiceRequestMapScreen({
    super.key,
    required this.serviceType,
    this.initialLocation,
  });

  @override
  State<ServiceRequestMapScreen> createState() =>
      _ServiceRequestMapScreenState();
}

class _ServiceRequestMapScreenState extends State<ServiceRequestMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(11.5564, 104.9282); // Phnom Penh default
  LatLng? _dropped;
  bool _locating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _dropped = widget.initialLocation;
      _center = widget.initialLocation!;
      _locating = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_center, 16);
      });
    } else {
      _detectCurrentLocation();
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _locationError = 'ត្រូវការការអនុញ្ញាតទីតាំង — សូមជ្រើសទីតាំងដោយដៃ';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = here;
        _locating = false;
        _locationError = null;
      });
      _mapController.move(here, 15);
    } catch (_) {
      setState(() {
        _locating = false;
        _locationError = 'មិនអាចទាញយកទីតាំងបានទេ — ចុចលើផែនទីដោយដៃ';
      });
    }
  }

  void _onMapTap(TapPosition _, LatLng point) =>
      setState(() => _dropped = point);

  Widget _buildProfileMarker() {
    final auth = context.read<AuthProvider>();
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

  Future<void> _openForm() async {
    if (_dropped == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestFormSheet(
        serviceType: widget.serviceType,
        location: _dropped!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ServiceTypes.infoOf(widget.serviceType);
    final Color accent = info['color'] as Color;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Stack(
        children: [
          // ── Full-screen map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.letsrent.app',
              ),
              MarkerLayer(
                markers: [
                  // Current location dot
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: _buildProfileMarker(),
                  ),
                  // Dropped pin
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
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/location.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                  info['icon'] as IconData,
                                  color: Colors.white,
                                  size: 18),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 10,
                            color: accent,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: accent, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar (back + title) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _MapButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 10,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            _serviceImgCfgs[widget.serviceType]?.imagePath ??
                                'assets/images/app_icon.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                info['icon'] as IconData,
                                color: accent,
                                size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ស្នើសេវា — ${info['label']}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF212121)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  color: accent,
                  onTap: _detectCurrentLocation,
                ),
              ],
            ),
          ),

          // ── Status banner ──
          if (_locating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: _MapBanner(
                icon: Icons.gps_fixed_rounded,
                text: 'កំពុងស្វែងរកទីតាំង...',
                color: _kGreen,
              ),
            )
          else if (_locationError != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: _MapBanner(
                icon: Icons.info_outline_rounded,
                text: _locationError!,
                color: const Color(0xFFF9A825),
              ),
            ),

          // ── Tap hint ──
          if (_dropped == null && !_locating)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: _MapBanner(
                icon: Icons.touch_app_rounded,
                text: 'ចុចលើផែនទីដើម្បីដាក់ទីតាំង',
                color: _kGreen,
              ),
            ),

          // ── Bottom CTA ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCTA(
              dropped: _dropped,
              accent: accent,
              serviceLabel: info['label'] as String,
              onUseCurrent: () async {
                await _detectCurrentLocation();
                if (!_locating) {
                  setState(() => _dropped = _center);
                  _mapController.move(_center, 16);
                }
              },
              onContinue: _openForm,
              onReset: () => setState(() => _dropped = null),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map helper widgets ───────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: color ?? const Color(0xFF424242), size: 20),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MapBanner(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF424242))),
          ),
        ],
      ),
    );
  }
}

class _BottomCTA extends StatelessWidget {
  final LatLng? dropped;
  final Color accent;
  final String serviceLabel;
  final VoidCallback onUseCurrent;
  final VoidCallback onContinue;
  final VoidCallback onReset;

  const _BottomCTA({
    required this.dropped,
    required this.accent,
    required this.serviceLabel,
    required this.onUseCurrent,
    required this.onContinue,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
              color: Color(0x16000000),
              blurRadius: 16,
              offset: Offset(0, -4))
        ],
      ),
      child: dropped == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('ជ្រើសរើសទីតាំង',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'ចុចលើផែនទី ឬ ប្រើទីតាំង GPS',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('ប្រើទីតាំង GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: onUseCurrent,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on_rounded,
                          color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ទីតាំងត្រូវបានជ្រើស ✓',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121))),
                          Text(
                            '${dropped!.latitude.toStringAsFixed(4)}, ${dropped!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onReset,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF757575)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('បំពេញទម្រង់សំណើ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: onContinue,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Request form sheet ───────────────────────────────────────────────────────

class _RequestFormSheet extends StatefulWidget {
  final String serviceType;
  final LatLng location;

  const _RequestFormSheet({
    required this.serviceType,
    required this.location,
  });

  @override
  State<_RequestFormSheet> createState() => _RequestFormSheetState();
}

class _RequestFormSheetState extends State<_RequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _birthCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  LandUnit _unit = LandUnit.hectare;
  String _currency = 'riel';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _addressCtrl.text =
        '${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    final error = await context.read<AppProvider>().addServiceRequest(
      farmerUid: user.uid,
      farmerName: _nameCtrl.text.trim(),
      placeOfBirth: _birthCtrl.text.trim(),
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      currentAddress: _addressCtrl.text.trim(),
      serviceType: widget.serviceType,
      landArea: double.tryParse(_areaCtrl.text.trim()) ?? 0,
      landUnit: _unit.value,
      offerPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      Navigator.of(context)
        ..pop() // close form sheet
        ..pop(); // back to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ បានផ្ញើសំណើ — រង់ចាំការឆ្លើយតបពីអ្នកផ្តល់សេវា'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ServiceTypes.infoOf(widget.serviceType);
    final Color accent = info['color'] as Color;

    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        _serviceImgCfgs[widget.serviceType]?.imagePath ??
                            'assets/images/app_icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            info['icon'] as IconData,
                            color: accent,
                            size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'សំណើសេវា',
                        style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        info['label'] as String,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF212121)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── ព័ត៌មានផ្ទាល់ខ្លួន ──
              _FormSection(title: 'ព័ត៌មានផ្ទាល់ខ្លួន'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration: _dec('ឈ្មោះ​​​​​​ (Name)', Icons.person_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'សូមបញ្ចូលឈ្មោះ' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _birthCtrl,
                decoration: _dec('ទីកន្លែងកំណើត (Birthplace)', Icons.home_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'សូមបញ្ចូលទីកន្លែងកំណើត' : null,
              ),
              const SizedBox(height: 20),

              // ── ព័ត៌មានសំណើ ──
              _FormSection(title: 'ព័ត៌មានសំណើ'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _addressCtrl,
                decoration: _dec(
                    'ទីតាំងបច្ចុប្បន្ន (Location)', Icons.location_on_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'សូមបញ្ចូលទីតាំង' : null,
              ),
              const SizedBox(height: 10),

              // Service type display (read-only)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.build_rounded,
                        size: 20, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ប្រភេទសេវា',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E))),
                        Text(
                          info['label'] as String,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF212121)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Land area + unit ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _areaCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          _dec('ទំហំដី (Area)', Icons.crop_square_rounded),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? 'បញ្ចូលទំហំដី' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<LandUnit>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: 'ឯកតា',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: _kGreen, width: 1.5)),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: LandUnit.rai, child: Text('រ៉ៃ')),
                        DropdownMenuItem(
                            value: LandUnit.hectare, child: Text('ហេកតា')),
                      ],
                      onChanged: (v) =>
                          setState(() => _unit = v ?? LandUnit.hectare),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Offer price with currency toggle ──
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(
                          _currency == 'riel'
                              ? 'ថ្លៃដែលផ្តល់ (រៀល) (Offer Price)'
                              : 'ថ្លៃដែលផ្តល់ (\$) (Offer Price)',
                          _currency == 'riel'
                              ? Icons.payments_rounded
                              : Icons.attach_money_rounded),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? 'បញ្ចូលតម្លៃ' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currency =
                            _currency == 'riel' ? 'dollar' : 'riel';
                      });
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _currency == 'riel'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currency == 'riel'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1565C0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currency == 'riel'
                                ? Icons.payments_rounded
                                : Icons.attach_money_rounded,
                            size: 18,
                            color: _currency == 'riel'
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currency == 'riel' ? 'រៀល' : 'USD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _currency == 'riel'
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Notes ──
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: _dec('ចំណាំ (ស្រេចចិត្ត)', Icons.note_alt_rounded),
              ),
              const SizedBox(height: 22),

              // ── Submit button ──
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: _submitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white)),
                            SizedBox(width: 12),
                            Text('កំពុងផ្ញើ...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text('ផ្ញើសំណើទៅអ្នកផ្តល់សេវា'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  const _FormSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: _kGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF424242))),
      ],
    );
  }
}