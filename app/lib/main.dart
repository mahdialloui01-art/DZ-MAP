import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

const navy = Color(0xFF101B33);
const teal = Color(0xFF16B8A6);
const algeriaBounds = LatLngBounds(
  LatLng(18.9, -8.7),
  LatLng(37.2, 12.1),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DzMapApp());
}

class DzMapApp extends StatelessWidget {
  const DzMapApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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

class AlgeriaMapScreen extends StatefulWidget {
  const AlgeriaMapScreen({super.key});
  @override
  State<AlgeriaMapScreen> createState() => _AlgeriaMapScreenState();
}

class _AlgeriaMapScreenState extends State<AlgeriaMapScreen> {
  final MapController _mapController = MapController();
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(28.0, 1.65),
                initialZoom: 4.6,
                minZoom: 4,
                maxZoom: 18,
                cameraConstraint: CameraConstraint.contain(
                  bounds: algeriaBounds,
                ),
                backgroundColor: Color(0xFFE7EEF2),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dz.dzmap',
                  maxNativeZoom: 19,
                  maxZoom: 19,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Align(alignment: Alignment.topCenter, child: _topBar()),
            ),
          ),
          Positioned(right: 16, bottom: 82, child: _mapControls()),
          Positioned(left: 12, bottom: 18, child: _attribution()),
        ],
      ),
    );
  }

  Widget _topBar() => Material(
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
                Text('DZ MAP', style: TextStyle(
                  color: navy, fontWeight: FontWeight.w900,
                  fontSize: 17, letterSpacing: 0.5,
                )),
                Text('خريطة الجزائر · محرك Flutter مباشر',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.layers_outlined, color: navy),
        ],
      ),
    ),
  );

  Widget _mapControls() => Column(
    children: [
      _controlButton(Icons.add, 'تكبير', () {
        final camera = _mapController.camera;
        _mapController.move(camera.center, camera.zoom + 1);
      }),
      const SizedBox(height: 8),
      _controlButton(Icons.remove, 'تصغير', () {
        final camera = _mapController.camera;
        _mapController.move(camera.center, camera.zoom - 1);
      }),
      const SizedBox(height: 14),
      _controlButton(
        _locating ? Icons.hourglass_top : Icons.my_location,
        'موقعي',
        _locating ? null : _locateMe,
        accent: true,
      ),
    ],
  );

  Widget _controlButton(
    IconData icon, String tooltip, VoidCallback? onPressed,
    {bool accent = false}
  ) => Material(
    elevation: 4,
    color: accent ? teal : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: accent ? Colors.white : navy),
    ),
  );

  Widget _attribution() => Material(
    color: Colors.white.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(9),
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () async {
        await launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text('© OpenStreetMap contributors',
          style: TextStyle(
            fontSize: 9, color: navy,
            decoration: TextDecoration.underline,
          )),
      ),
    ),
  );

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
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
      _mapController.move(
        LatLng(position.latitude, position.longitude), 15,
      );
      _message('تم الانتقال إلى موقعك.');
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
