import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/map_settings_service.dart';
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
  MapSettings? _mapSettings;

  @override
  void initState() {
    super.initState();
    _loadMapSettings();
  }

  Future<void> _loadMapSettings() async {
    final settings = await MapSettingsService.getSettings(force: true);
    if (!mounted) return;
    setState(() => _mapSettings = settings);
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
      if (_shouldUseGooglePicker && !widget.readOnly) {
        setState(() => _zoom = 16);
      } else {
        _move(point, 16);
      }
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

    if (_displayMarkers.length >= 3) {
      return [_displayMarkers[2], _displayMarkers[1]];
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

  bool get _shouldUseNativeAndroidMap => false;

  bool get _shouldUseGooglePicker =>
      _mapSettings?.canUseGoogle == true &&
      _mapSettings?.mapsJavascriptEnabled == true;

  bool get _shouldUseGoogleRouteEmbed =>
      _mapSettings?.canUseGoogle == true && _mapSettings?.embedEnabled == true;

  Future<void> _openExternalMap({
    bool route = false,
    AppMapMarker? marker,
  }) async {
    if (route && _routeMarkers.length >= 2) {
      final start = _routeMarkers[0];
      final end = _routeMarkers[1];
      final geoUri = Uri.parse(
        'google.navigation:q=${end.lat},${end.lng}&mode=d',
      );
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }

      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${start.lat},${start.lng}&destination=${end.lat},${end.lng}&travelmode=driving',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    } else if (marker != null) {
      final geoUri = Uri.parse(
        'geo:${marker.lat},${marker.lng}?q=${marker.lat},${marker.lng}',
      );
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }

      final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${marker.lat},${marker.lng}',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
      if (_shouldUseNativeAndroidMap) {
        return _NativeGoogleRouteMapScreen(
          title: widget.title,
          markers: _displayMarkers,
          routeMarkers: routeMarkers,
          distanceKm: _routeDistanceKm,
          onOpenRoute: () => _openExternalMap(route: true),
          onOpenMarker: (marker) => _openExternalMap(marker: marker),
        );
      }
      if (_shouldUseGoogleRouteEmbed) {
        return _GoogleRouteMapScreen(
          title: widget.title,
          markers: _displayMarkers,
          routeMarkers: routeMarkers,
          distanceKm: _routeDistanceKm,
          apiKey: _mapSettings!.browserApiKey!,
          onOpenRoute: () => _openExternalMap(route: true),
          onOpenMarker: (marker) => _openExternalMap(marker: marker),
        );
      }
    }

    if (!widget.readOnly && _shouldUseNativeAndroidMap) {
      return _NativeGoogleLocationPickerScreen(
        title: widget.title,
        selected: _selected,
        locating: _locating,
        message: _message,
        onChanged: (point) => setState(() => _selected = point),
        onCurrentLocation: _useCurrentLocation,
      );
    }

    if (!widget.readOnly && _shouldUseGooglePicker) {
      return _GoogleLocationPickerScreen(
        title: widget.title,
        selected: _selected,
        locating: _locating,
        message: _message,
        apiKey: _mapSettings!.browserApiKey!,
        onChanged: (point) => setState(() => _selected = point),
        onCurrentLocation: _useCurrentLocation,
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

class _NativeGoogleLocationPickerScreen extends StatefulWidget {
  const _NativeGoogleLocationPickerScreen({
    required this.title,
    required this.selected,
    required this.locating,
    required this.message,
    required this.onChanged,
    required this.onCurrentLocation,
  });

  final String title;
  final LatLng selected;
  final bool locating;
  final String? message;
  final ValueChanged<LatLng> onChanged;
  final Future<void> Function() onCurrentLocation;

  @override
  State<_NativeGoogleLocationPickerScreen> createState() =>
      _NativeGoogleLocationPickerScreenState();
}

class _NativeGoogleLocationPickerScreenState
    extends State<_NativeGoogleLocationPickerScreen> {
  gmap.GoogleMapController? _controller;
  bool _movingFromCode = false;

  gmap.LatLng get _selected =>
      gmap.LatLng(widget.selected.latitude, widget.selected.longitude);

  @override
  void didUpdateWidget(covariant _NativeGoogleLocationPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _animateTo(widget.selected, zoom: 16);
    }
  }

  Future<void> _animateTo(LatLng point, {double? zoom}) async {
    final controller = _controller;
    if (controller == null) return;
    _movingFromCode = true;
    await controller.animateCamera(
      gmap.CameraUpdate.newCameraPosition(
        gmap.CameraPosition(
          target: gmap.LatLng(point.latitude, point.longitude),
          zoom: zoom ?? 16,
        ),
      ),
    );
    _movingFromCode = false;
  }

  void _setPoint(gmap.LatLng point) {
    widget.onChanged(LatLng(point.latitude, point.longitude));
  }

  Future<void> _zoomBy(double delta) async {
    await _controller?.animateCamera(
      delta > 0 ? gmap.CameraUpdate.zoomIn() : gmap.CameraUpdate.zoomOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          gmap.GoogleMap(
            initialCameraPosition: gmap.CameraPosition(
              target: _selected,
              zoom: 16,
            ),
            onMapCreated: (controller) => _controller = controller,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onTap: (point) {
              _setPoint(point);
              _animateTo(LatLng(point.latitude, point.longitude));
            },
            onCameraMove: (position) {
              if (!_movingFromCode) _setPoint(position.target);
            },
            markers: {
              gmap.Marker(
                markerId: const gmap.MarkerId('selected'),
                position: _selected,
                draggable: true,
                onDragEnd: (point) {
                  _setPoint(point);
                  _animateTo(LatLng(point.latitude, point.longitude));
                },
              ),
            },
          ),
          const Center(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: _CenterPin(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 18,
            child: SafeArea(child: _GooglePickerHint(message: widget.message)),
          ),
          Positioned(
            right: 16,
            top: 86,
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
                    icon: widget.locating
                        ? Icons.hourglass_empty_rounded
                        : Icons.my_location_rounded,
                    onTap: widget.locating ? null : widget.onCurrentLocation,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _PickerInfoSheet(
                selected: widget.selected,
                message: widget.message,
                locating: widget.locating,
                readOnly: false,
                onCurrentLocation: widget.onCurrentLocation,
                onConfirm: () => Navigator.of(context).pop(
                  PickedLocation(
                    lat: widget.selected.latitude,
                    lng: widget.selected.longitude,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NativeGoogleRouteMapScreen extends StatefulWidget {
  const _NativeGoogleRouteMapScreen({
    required this.title,
    required this.markers,
    required this.routeMarkers,
    required this.distanceKm,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final String title;
  final List<AppMapMarker> markers;
  final List<AppMapMarker> routeMarkers;
  final double? distanceKm;
  final VoidCallback onOpenRoute;
  final ValueChanged<AppMapMarker> onOpenMarker;

  @override
  State<_NativeGoogleRouteMapScreen> createState() =>
      _NativeGoogleRouteMapScreenState();
}

class _NativeGoogleRouteMapScreenState
    extends State<_NativeGoogleRouteMapScreen> {
  gmap.GoogleMapController? _controller;

  gmap.LatLngBounds get _bounds {
    final points = widget.routeMarkers
        .map((marker) => gmap.LatLng(marker.lat, marker.lng))
        .toList();
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points.skip(1)) {
      south = point.latitude < south ? point.latitude : south;
      north = point.latitude > north ? point.latitude : north;
      west = point.longitude < west ? point.longitude : west;
      east = point.longitude > east ? point.longitude : east;
    }
    return gmap.LatLngBounds(
      southwest: gmap.LatLng(south, west),
      northeast: gmap.LatLng(north, east),
    );
  }

  Set<gmap.Marker> get _markers => widget.markers
      .map(
        (marker) => gmap.Marker(
          markerId: gmap.MarkerId(marker.label),
          position: gmap.LatLng(marker.lat, marker.lng),
          infoWindow: gmap.InfoWindow(title: marker.label),
        ),
      )
      .toSet();

  Set<gmap.Polyline> get _polylines => {
    gmap.Polyline(
      polylineId: const gmap.PolylineId('route'),
      points: widget.routeMarkers
          .map((marker) => gmap.LatLng(marker.lat, marker.lng))
          .toList(growable: false),
      color: Theme.of(context).colorScheme.primary,
      width: 5,
    ),
  };

  Future<void> _fitRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _controller?.animateCamera(
      gmap.CameraUpdate.newLatLngBounds(_bounds, 72),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.routeMarkers[0];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: gmap.GoogleMap(
              initialCameraPosition: gmap.CameraPosition(
                target: gmap.LatLng(start.lat, start.lng),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _controller = controller;
                _fitRoute();
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 12,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _GoogleRouteActions(
                  markers: widget.markers,
                  routeMarkers: widget.routeMarkers,
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

class _GoogleLocationPickerScreen extends StatefulWidget {
  const _GoogleLocationPickerScreen({
    required this.title,
    required this.selected,
    required this.locating,
    required this.message,
    required this.apiKey,
    required this.onChanged,
    required this.onCurrentLocation,
  });

  final String title;
  final LatLng selected;
  final bool locating;
  final String? message;
  final String apiKey;
  final ValueChanged<LatLng> onChanged;
  final Future<void> Function() onCurrentLocation;

  @override
  State<_GoogleLocationPickerScreen> createState() =>
      _GoogleLocationPickerScreenState();
}

class _GoogleLocationPickerScreenState
    extends State<_GoogleLocationPickerScreen> {
  late final WebViewController _webController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'LocationChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            final lat = (data['lat'] as num).toDouble();
            final lng = (data['lng'] as num).toDouble();
            widget.onChanged(LatLng(lat, lng));
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_mapHtml(widget.selected));
  }

  @override
  void didUpdateWidget(covariant _GoogleLocationPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final lat = widget.selected.latitude;
      final lng = widget.selected.longitude;
      _webController.runJavaScript('window.setPickedLocation($lat, $lng);');
    }
  }

  String _mapHtml(LatLng point) {
    final key = Uri.encodeComponent(widget.apiKey);
    final lat = point.latitude;
    final lng = point.longitude;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    html, body, #map { margin:0; padding:0; width:100%; height:100%; overflow:hidden; }
  </style>
  <script src="https://maps.googleapis.com/maps/api/js?key=$key&v=weekly"></script>
</head>
<body>
  <div id="map"></div>
  <script>
    let map;
    let marker;
    let lastNotify = 0;
    function notify(latLng) {
      const now = Date.now();
      if (now - lastNotify < 350) return;
      lastNotify = now;
      LocationChannel.postMessage(JSON.stringify({ lat: latLng.lat(), lng: latLng.lng() }));
    }
    function init() {
      const center = { lat: $lat, lng: $lng };
      map = new google.maps.Map(document.getElementById('map'), {
        center,
        zoom: 16,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: false,
        clickableIcons: false,
        gestureHandling: 'greedy',
        styles: [
          { featureType: 'poi.business', stylers: [{ visibility: 'off' }] },
          { featureType: 'transit', stylers: [{ visibility: 'off' }] }
        ]
      });
      marker = new google.maps.Marker({ position: center, map, draggable: true });
      map.addListener('click', (event) => {
        marker.setPosition(event.latLng);
        map.panTo(event.latLng);
        notify(event.latLng);
      });
      marker.addListener('dragend', () => {
        const position = marker.getPosition();
        map.panTo(position);
        notify(position);
      });
      map.addListener('idle', () => {
        const center = map.getCenter();
        marker.setPosition(center);
        notify(center);
      });
    }
    window.setPickedLocation = function(lat, lng) {
      if (!map || !marker) return;
      const next = new google.maps.LatLng(lat, lng);
      marker.setPosition(next);
      map.setCenter(next);
      map.setZoom(16);
    }
    init();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          SizedBox.expand(child: WebViewWidget(controller: _webController)),
          if (_loading) const Center(child: LogoLoader(showLabel: true)),
          Positioned(
            left: 16,
            right: 16,
            top: 18,
            child: SafeArea(child: _GooglePickerHint(message: widget.message)),
          ),
          Positioned(
            right: 16,
            top: 86,
            child: SafeArea(
              child: _RoundMapButton(
                icon: widget.locating
                    ? Icons.hourglass_empty_rounded
                    : Icons.my_location_rounded,
                onTap: widget.locating ? null : widget.onCurrentLocation,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _PickerInfoSheet(
                selected: widget.selected,
                message: widget.message,
                locating: widget.locating,
                readOnly: false,
                onCurrentLocation: widget.onCurrentLocation,
                onConfirm: () => Navigator.of(context).pop(
                  PickedLocation(
                    lat: widget.selected.latitude,
                    lng: widget.selected.longitude,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GooglePickerHint extends StatelessWidget {
  const _GooglePickerHint({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'ম্যাপে ট্যাপ করুন বা ম্যাপ সরিয়ে সঠিক লোকেশন নিন',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleRouteMapScreen extends StatefulWidget {
  const _GoogleRouteMapScreen({
    required this.title,
    required this.markers,
    required this.routeMarkers,
    required this.distanceKm,
    required this.apiKey,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final String title;
  final List<AppMapMarker> markers;
  final List<AppMapMarker> routeMarkers;
  final double? distanceKm;
  final String apiKey;
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
    final start = widget.routeMarkers[0];
    final end = widget.routeMarkers[1];
    final params = Uri(
      queryParameters: {
        'key': widget.apiKey,
        'origin': '${start.lat},${start.lng}',
        'destination': '${end.lat},${end.lng}',
        'mode': 'driving',
      },
    ).query;
    return 'https://www.google.com/maps/embed/v1/directions?$params';
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
                  routeMarkers: widget.routeMarkers,
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
    required this.routeMarkers,
    required this.distanceKm,
    required this.onOpenRoute,
    required this.onOpenMarker,
  });

  final List<AppMapMarker> markers;
  final List<AppMapMarker> routeMarkers;
  final double? distanceKm;
  final VoidCallback onOpenRoute;
  final ValueChanged<AppMapMarker> onOpenMarker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final routeStart = routeMarkers[0];
    final routeEnd = routeMarkers[1];
    final restaurant = markers.isNotEmpty ? markers[0] : null;
    final delivery = markers.length > 1 ? markers[1] : null;
    final rider = markers.length > 2 ? markers[2] : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                distanceKm == null
                    ? (rider == null
                          ? 'রেস্টুরেন্ট থেকে ডেলিভারি ম্যাপ'
                          : 'রাইডার লাইভ ট্র্যাকিং')
                    : (rider == null
                          ? 'রুট দূরত্ব ${distanceKm!.toStringAsFixed(2)} KM'
                          : 'রাইডার থেকে কাস্টমার ${distanceKm!.toStringAsFixed(2)} KM'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              height: 40,
              child: FilledButton(
                onPressed: onOpenRoute,
                child: const Text('Route'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${routeStart.label} → ${routeEnd.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (restaurant != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onOpenMarker(restaurant),
                  child: const Text('Restaurant'),
                ),
              ),
            if (restaurant != null && delivery != null)
              const SizedBox(width: 8),
            if (delivery != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onOpenMarker(delivery),
                  child: const Text('Delivery'),
                ),
              ),
            if (rider != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onOpenMarker(rider),
                  child: const Text('Rider'),
                ),
              ),
            ],
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
