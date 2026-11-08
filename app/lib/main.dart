import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

const navy = Color(0xFF101B33);
const teal = Color(0xFF16B8A6);

// OpenFreeMap explicitly permits commercial use and requires attribution.
// Its public service currently has no SLA; review service terms before scale-up.
const mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
const mapCopyrightUrl = 'https://www.openstreetmap.org/copyright';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DzMapApp());
}

class DzMapApp extends StatelessWidget {
  const DzMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DZ MAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AlgeriaMapScreen(),
      ),
    );
  }
}

class AlgeriaMapScreen extends StatefulWidget {
  const AlgeriaMapScreen({super.key});

  @override
  State<AlgeriaMapScreen> createState() => _AlgeriaMapScreenState();
}

class _AlgeriaMapScreenState extends State<AlgeriaMapScreen> {
  MapLibreMapController? _controller;
  bool _locating = false;
  bool _mapReady = false;
  bool _maskLoading = false;
  bool _maskApplied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              styleString: mapStyleUrl,
              // Use Android hybrid composition to avoid a blank TextureView
              // surface on devices where Flutter texture compositing fails.
              androidView: const AndroidMapView(
                // TextureView is composed as a Flutter texture. This avoids
                // SurfaceView clipping/blank-region issues on some Android devices.
                surface: AndroidMapSurface.textureView,
                composition: AndroidComposition.flutter,
              ),
              // Keep map navigation focused on Algeria's geographic extent.
              cameraTargetBounds: CameraTargetBounds(
                LatLngBounds(
                  southwest: LatLng(18.9, -8.7),
                  northeast: LatLng(37.2, 12.1),
                ),
              ),
              initialCameraPosition: const CameraPosition(
                target: LatLng(28.0, 1.65),
                zoom: 4.6,
              ),
              compassEnabled: true,
              myLocationEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
              },
              onStyleLoadedCallback: () {
                if (mounted) setState(() => _mapReady = true);
                _loadAlgeriaMask();
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: _topBar(),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 82,
            child: _mapControls(),
          ),
          Positioned(
            left: 12,
            bottom: 18,
            child: _attribution(),
          ),
          if (!_mapReady)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 9),
                        Text('جارٍ تحميل خريطة الجزائر...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  // Fetch the official country-level outline from geoBoundaries (DZA ADM0),
  // then draw a world-sized polygon with Algeria cut out as a transparent hole.
  // This keeps the basemap visible only inside Algeria without fabricating
  // boundary coordinates in the app.
  Future<void> _loadAlgeriaMask() async {
    if (_maskLoading || _maskApplied) return;
    final controller = _controller;
    if (controller == null) return;
    _maskLoading = true;
    try {
      final metadataResponse = await http.get(
        Uri.parse('https://www.geoboundaries.org/api/current/gbOpen/DZA/ADM0/'),
      ).timeout(const Duration(seconds: 25));
      if (metadataResponse.statusCode != 200) {
        throw Exception('geoBoundaries metadata unavailable');
      }
      final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
      final geometryUrl = (metadata['simplifiedGeometryGeoJSON'] as String?)?.isNotEmpty == true
          ? metadata['simplifiedGeometryGeoJSON'] as String
          : metadata['gjDownloadURL'] as String;
      final boundaryResponse = await http.get(Uri.parse(geometryUrl))
          .timeout(const Duration(seconds: 35));
      if (boundaryResponse.statusCode != 200) {
        throw Exception('Algeria boundary unavailable');
      }
      final boundaryData = jsonDecode(boundaryResponse.body) as Map<String, dynamic>;
      final features = boundaryData['features'] as List<dynamic>;
      if (features.isEmpty) throw Exception('Empty Algeria boundary');
      final feature = features.first as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final dynamic rawCoordinates = geometry['coordinates'];
      final List<List<List<num>>> exteriorRings = [];
      if (type == 'Polygon') {
        final rings = rawCoordinates as List<dynamic>;
        exteriorRings.add((rings.first as List<dynamic>)
            .map((point) => (point as List<dynamic>).cast<num>())
            .toList());
      } else if (type == 'MultiPolygon') {
        for (final polygon in rawCoordinates as List<dynamic>) {
          final rings = polygon as List<dynamic>;
          exteriorRings.add((rings.first as List<dynamic>)
              .map((point) => (point as List<dynamic>).cast<num>())
              .toList());
        }
      } else {
        throw Exception('Unsupported Algeria boundary geometry: $type');
      }

      // GeoJSON requires the exterior world ring counter-clockwise and
      // interior rings clockwise for consistent polygon-hole rendering.
      final worldRing = [
        [-180, -85], [180, -85], [180, 85], [-180, 85], [-180, -85],
      ];
      final holes = exteriorRings.map((ring) => ring.reversed.toList()).toList();
      final mask = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'name': 'Outside Algeria'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [worldRing, ...holes],
            },
          },
        ],
      };

      await controller.addGeoJsonSource('dz-algeria-mask-source', mask);
      await controller.addFillLayer(
        'dz-algeria-mask-source',
        'dz-algeria-outside-mask',
        const FillLayerProperties(
          fillColor: '#DCE5E8',
          fillOpacity: 0.96,
          fillAntialias: true,
        ),
      );
      await controller.addGeoJsonSource('dz-algeria-border-source', {
        'type': 'FeatureCollection',
        'features': [feature],
      });
      await controller.addLineLayer(
        'dz-algeria-border-source',
        'dz-algeria-border-line',
        const LineLayerProperties(
          lineColor: '#16B8A6',
          lineWidth: 2.2,
          lineOpacity: 1,
        ),
      );
      _maskApplied = true;
    } catch (error) {
      debugPrint('DZ MAP Algeria mask could not be applied: $error');
      if (mounted) _message('تعذر تحميل حدود الجزائر. تحقق من الإنترنت.');
    } finally {
      _maskLoading = false;
    }
  }

  Widget _topBar() {
    return Material(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.map_rounded, color: teal, size: 25),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DZ MAP',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'خريطة الجزائر',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.layers_outlined, color: navy),
          ],
        ),
      ),
    );
  }

  Widget _mapControls() {
    return Column(
      children: [
        _controlButton(
          icon: Icons.add,
          tooltip: 'تكبير',
          onPressed: () => _zoom(1),
        ),
        const SizedBox(height: 8),
        _controlButton(
          icon: Icons.remove,
          tooltip: 'تصغير',
          onPressed: () => _zoom(-1),
        ),
        const SizedBox(height: 14),
        _controlButton(
          icon: _locating ? Icons.hourglass_top : Icons.my_location,
          tooltip: 'موقعي',
          onPressed: _locating ? null : _locateMe,
          accent: true,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool accent = false,
  }) {
    return Material(
      elevation: 4,
      color: accent ? teal : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: accent ? Colors.white : navy),
      ),
    );
  }

  Widget _attribution() {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(9),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          final uri = Uri.parse(mapCopyrightUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            'OpenFreeMap · © OpenStreetMap · geoBoundaries',
            style: TextStyle(
              fontSize: 9,
              color: navy,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _zoom(double amount) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.zoomBy(amount));
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _message('فعّل خدمة GPS في الهاتف ثم أعد المحاولة.');
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _message('لم تسمح للتطبيق باستعمال موقعك.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _message('إذن الموقع مرفوض نهائياً. اسمح به من إعدادات التطبيق.');
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      final controller = _controller;
      if (controller == null) {
        _message('الخريطة ما زالت تحمّل. أعد المحاولة بعد لحظات.');
        return;
      }
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
      _message('تم الانتقال إلى موقعك.');
    } on LocationServiceDisabledException {
      _message('خدمة GPS غير مفعّلة في الهاتف.');
    } on PermissionDeniedException {
      _message('إذن الموقع غير متاح. راجع إعدادات التطبيق.');
    } catch (_) {
      _message('تعذر تحديد الموقع. تحقق من GPS والإنترنت ثم أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
