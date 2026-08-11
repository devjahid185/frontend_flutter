import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'logo_loader.dart';

class PickedLocation {
  const PickedLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class AppMapMarker {
  const AppMapMarker({
    required this.lat,
    required this.lng,
    required this.label,
    this.icon = Icons.location_on_rounded,
    this.color,
  });

  final double lat;
  final double lng;
  final String label;
  final IconData icon;
  final Color? color;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'লোকেশন নির্বাচন',
    this.readOnly = false,
    this.markers = const [],
  });

  final double? initialLat;
  final double? initialLng;
  final String title;
  final bool readOnly;
  final List<AppMapMarker> markers;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallback = LatLng(22.6850, 90.6482);

  final _controller = MapController();
  late LatLng _selected = widget.initialLat != null && widget.initialLng != null
      ? LatLng(widget.initialLat!, widget.initialLng!)
      : _fallback;
  bool _locating = false;
  String? _message;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _message = 'লোকেশন সার্ভিস চালু করুন।');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(
          () =>
              _message = 'লোকেশন permission দিলে current location নেওয়া যাবে।',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        setState(
          () => _message = 'App settings থেকে লোকেশন permission চালু করুন।',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selected = point);
      _controller.move(point, 16);
    } catch (_) {
      setState(() => _message = 'লোকেশন নেওয়া যায়নি। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markers = [
      ...widget.markers.map(
        (marker) => Marker(
          point: LatLng(marker.lat, marker.lng),
          width: 92,
          height: 66,
          child: _MapPin(marker: marker),
        ),
      ),
      if (!widget.readOnly)
        Marker(
          point: _selected,
          width: 100,
          height: 70,
          child: const _MapPin(
            marker: AppMapMarker(
              lat: 0,
              lng: 0,
              label: 'নির্বাচিত',
              icon: Icons.add_location_alt_rounded,
            ),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              onTap: widget.readOnly
                  ? null
                  : (_, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bholavashi.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                color: scheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.readOnly
                            ? 'ম্যাপে লোকেশন দেখুন'
                            : 'পিন যেখানে থাকবে সেটাই ডেলিভারি লোকেশন হবে',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _message!,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _locating ? null : _useCurrentLocation,
                              icon: _locating
                                  ? const LogoLoader(size: 18)
                                  : const Icon(Icons.my_location_rounded),
                              label: Text(
                                _locating
                                    ? 'নেওয়া হচ্ছে...'
                                    : 'Current location',
                              ),
                            ),
                          ),
                          if (!widget.readOnly) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(
                                  PickedLocation(
                                    lat: _selected.latitude,
                                    lng: _selected.longitude,
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('সিলেক্ট'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? FloatingActionButton.small(
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.marker});

  final AppMapMarker marker;

  @override
  Widget build(BuildContext context) {
    final color = marker.color ?? Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              marker.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Icon(marker.icon, color: color, size: 34),
      ],
    );
  }
}

double? readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
