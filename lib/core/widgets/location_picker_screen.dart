import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  double _zoom = 15;
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
      _move(point, 16);
    } catch (_) {
      setState(() => _message = 'লোকেশন নেওয়া যায়নি। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _move(LatLng point, double zoom) {
    setState(() {
      _zoom = zoom.clamp(5, 18).toDouble();
      _selected = point;
    });
    _controller.move(point, _zoom);
  }

  void _zoomBy(double delta) {
    _move(_selected, _zoom + delta);
  }

  List<AppMapMarker> get _displayMarkers => widget.markers;

  List<AppMapMarker> get _routeMarkers {
    if (!widget.readOnly || _displayMarkers.length < 2) {
      return const [];
    }

    return _displayMarkers.take(2).toList();
  }

  double? get _routeDistanceKm {
    final route = _routeMarkers;
    if (route.length < 2) return null;

    return const Distance().as(
      LengthUnit.Kilometer,
      LatLng(route[0].lat, route[0].lng),
      LatLng(route[1].lat, route[1].lng),
    );
  }

  Future<void> _openExternalMap({
    bool route = false,
    AppMapMarker? marker,
  }) async {
    Uri? uri;
    if (route && _routeMarkers.length >= 2) {
      final start = _routeMarkers[0];
      final end = _routeMarkers[1];
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${start.lat},${start.lng}&destination=${end.lat},${end.lng}&travelmode=driving',
      );
    } else if (marker != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${marker.lat},${marker.lng}',
      );
    }

    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final routeMarkers = _routeMarkers;
    final routePoints = routeMarkers
        .map((marker) => LatLng(marker.lat, marker.lng))
        .toList(growable: false);
    final markers = [
      ..._displayMarkers.map(
        (marker) => Marker(
          point: LatLng(marker.lat, marker.lng),
          width: 92,
          height: 66,
          child: _MapPin(marker: marker),
        ),
      ),
    ];
    if (widget.readOnly && routeMarkers.length >= 2) {
      return _GoogleRouteMapScreen(
        title: widget.title,
        markers: routeMarkers,
        distanceKm: _routeDistanceKm,
        onOpenRoute: () => _openExternalMap(route: true),
        onOpenMarker: (marker) => _openExternalMap(marker: marker),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: _zoom,
              maxZoom: 18,
              minZoom: 5,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom,
                enableMultiFingerGestureRace: true,
              ),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selected = camera.center;
                    _zoom = camera.zoom;
                  });
                }
              },
              onTap: widget.readOnly
                  ? null
                  : (_, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.bholavashi.app',
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                ),
              ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: scheme.primary,
                      strokeWidth: 5,
                      borderColor: scheme.surface,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (!widget.readOnly)
            const Center(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 34),
                  child: _CenterPin(),
                ),
              ),
            ),
          Positioned(
            right: 16,
            top: 18,
            child: SafeArea(
              child: Column(
                children: [
                  _RoundMapButton(
                    icon: Icons.add_rounded,
                    onTap: () => _zoomBy(1),
                  ),
                  const SizedBox(height: 8),
                  _RoundMapButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _zoomBy(-1),
                  ),
                  const SizedBox(height: 8),
                  _RoundMapButton(
                    icon: _locating
                        ? Icons.hourglass_empty_rounded
                        : Icons.my_location_rounded,
                    onTap: _locating ? null : _useCurrentLocation,
                  ),
                ],
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              left: 16,
              right: 16,
              top: 18,
              child: SafeArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pan_tool_alt_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'ম্যাপ সরিয়ে পিনটি আপনার ঠিকানার উপর রাখুন',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: widget.readOnly && routeMarkers.length >= 2
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.22,
                      ),
                      child: _RouteInfoSheet(
                        markers: routeMarkers,
                        distanceKm: _routeDistanceKm,
                        onOpenRoute: () => _openExternalMap(route: true),
                        onOpenMarker: (marker) =>
                            _openExternalMap(marker: marker),
                      ),
                    )
                  : _PickerInfoSheet(
                      selected: _selected,
                      message: _message,
                      locating: _locating,
                      readOnly: widget.readOnly,
                      onCurrentLocation: _useCurrentLocation,
                      onConfirm: () => Navigator.of(context).pop(
                        PickedLocation(
                          lat: _selected.latitude,
                          lng: _selected.longitude,
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

class _GoogleRouteMapScreen extends StatefulWidget {
  const _GoogleRouteMapScreen({
    required this.title,
    required this.markers,
    required this.distanceKm,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final String title;
  final List<AppMapMarker> markers;
  final double? distanceKm;
  final VoidCallback onOpenRoute;
  final ValueChanged<AppMapMarker> onOpenMarker;

  @override
  State<_GoogleRouteMapScreen> createState() => _GoogleRouteMapScreenState();
}

class _GoogleRouteMapScreenState extends State<_GoogleRouteMapScreen> {
  late final WebViewController _webController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_mapHtml);
  }

  String get _embedUrl {
    final start = widget.markers[0];
    final end = widget.markers[1];
    return 'https://maps.google.com/maps?saddr=${start.lat},${start.lng}&daddr=${end.lat},${end.lng}&output=embed';
  }

  String get _mapHtml {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    html, body, iframe {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      border: 0;
      overflow: hidden;
      touch-action: auto;
    }
  </style>
</head>
<body>
  <iframe
    src="$_embedUrl"
    allowfullscreen
    loading="lazy"
    referrerpolicy="no-referrer-when-downgrade">
  </iframe>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: WebViewWidget(controller: _webController),
                ),
                if (_loading) const Center(child: LogoLoader(showLabel: true)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 12,
              color: scheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _GoogleRouteActions(
                  markers: widget.markers,
                  distanceKm: widget.distanceKm,
                  onOpenRoute: widget.onOpenRoute,
                  onOpenMarker: widget.onOpenMarker,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => Navigator.of(context).pop(),
        child: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _GoogleRouteActions extends StatelessWidget {
  const _GoogleRouteActions({
    required this.markers,
    required this.distanceKm,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final List<AppMapMarker> markers;
  final double? distanceKm;
  final VoidCallback onOpenRoute;
  final ValueChanged<AppMapMarker> onOpenMarker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = markers[0];
    final end = markers[1];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                distanceKm == null
                    ? 'রেস্টুরেন্ট থেকে ডেলিভারি ম্যাপ'
                    : 'রুট দূরত্ব ${distanceKm!.toStringAsFixed(2)} KM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: onOpenRoute, child: const Text('Route')),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${start.label} → ${end.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onOpenMarker(start),
                child: const Text('Restaurant'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onOpenMarker(end),
                child: const Text('Delivery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteInfoSheet extends StatelessWidget {
  const _RouteInfoSheet({
    required this.markers,
    required this.distanceKm,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final List<AppMapMarker> markers;
  final double? distanceKm;
  final VoidCallback onOpenRoute;
  final ValueChanged<AppMapMarker> onOpenMarker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = markers[0];
    final end = markers[1];

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      color: scheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'রেস্টুরেন্ট থেকে ডেলিভারি ম্যাপ',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        distanceKm == null
                            ? 'রেস্টুরেন্ট ও কাস্টমার লোকেশন একসাথে'
                            : 'রেস্টুরেন্ট ও কাস্টমার লোকেশন একসাথে • ${distanceKm!.toStringAsFixed(2)} KM',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onOpenRoute,
                  child: const Text('Open route'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoutePointCard(marker: start, title: 'রেস্টুরেন্ট'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RoutePointCard(marker: end, title: 'কাস্টমার'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onOpenMarker(start),
                    child: const Text('Open restaurant'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onOpenMarker(end),
                    child: const Text('Open delivery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePointCard extends StatelessWidget {
  const _RoutePointCard({required this.marker, required this.title});

  final AppMapMarker marker;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            marker.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${marker.lat.toStringAsFixed(6)}, ${marker.lng.toStringAsFixed(6)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PickerInfoSheet extends StatelessWidget {
  const _PickerInfoSheet({
    required this.selected,
    required this.message,
    required this.locating,
    required this.readOnly,
    required this.onCurrentLocation,
    required this.onConfirm,
  });

  final LatLng selected;
  final String? message;
  final bool locating;
  final bool readOnly;
  final VoidCallback onCurrentLocation;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
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
              readOnly ? 'ম্যাপে লোকেশন দেখুন' : 'এই লোকেশনটি ব্যবহার করবেন?',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${selected.latitude.toStringAsFixed(6)}, ${selected.longitude.toStringAsFixed(6)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locating ? null : onCurrentLocation,
                    icon: locating
                        ? const LogoLoader(size: 18)
                        : const Icon(Icons.my_location_rounded),
                    label: Text(locating ? 'নেওয়া হচ্ছে...' : 'আমার লোকেশন'),
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('এই লোকেশন নিন'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'ডেলিভারি এখানে',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Icon(
          Icons.location_on_rounded,
          color: scheme.primary,
          size: 46,
          shadows: const [Shadow(color: Color(0x33000000), blurRadius: 8)],
        ),
      ],
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 5,
      color: scheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: scheme.onSurface),
        ),
      ),
    );
  }
}

double? readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
