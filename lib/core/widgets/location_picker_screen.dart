import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'logo_loader.dart';

class PickedLocation {
  const PickedLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'লোকেশন নির্বাচন',
    this.readOnly = false,
    this.markers = const {},
  });

  final double? initialLat;
  final double? initialLng;
  final String title;
  final bool readOnly;
  final Set<Marker> markers;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallback = LatLng(22.6850, 90.6482);

  GoogleMapController? _controller;
  late LatLng _selected = widget.initialLat != null && widget.initialLng != null
      ? LatLng(widget.initialLat!, widget.initialLng!)
      : _fallback;
  bool _locating = false;
  String? _message;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

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
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } catch (_) {
      setState(() => _message = 'লোকেশন নেওয়া যায়নি। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markers = {
      ...widget.markers,
      if (!widget.readOnly)
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selected,
          infoWindow: const InfoWindow(title: 'নির্বাচিত লোকেশন'),
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selected, zoom: 15),
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (controller) => _controller = controller,
            onTap: widget.readOnly
                ? null
                : (point) => setState(() => _selected = point),
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

double? readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
