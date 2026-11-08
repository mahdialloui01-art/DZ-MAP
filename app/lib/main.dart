import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

const navy = Color(0xFF101B33);
const teal = Color(0xFF16B8A6);
const mapStyleUrl = String.fromEnvironment('DZ_MAP_STYLE_URL');
const mapAttribution = String.fromEnvironment('DZ_MAP_ATTRIBUTION');
const mapAttributionUrl = String.fromEnvironment('DZ_MAP_ATTRIBUTION_URL');

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
        child: HomeMapScreen(),
      ),
    );
  }
}

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _mapArea()),
            Positioned(top: 14, right: 16, left: 16, child: _searchBar()),
            Positioned(top: 82, right: 16, child: _sellerChip()),
            Positioned(
              right: 16,
              bottom: 190,
              child: FloatingActionButton.small(
                heroTag: 'my-location',
                backgroundColor: Colors.white,
                foregroundColor: navy,
                onPressed: () => _message('سيتم تفعيل GPS بعد إضافة أذونات الموقع.'),
                child: const Icon(Icons.my_location),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 190,
              child: FloatingActionButton.small(
                heroTag: 'add-shop',
                backgroundColor: teal,
                foregroundColor: Colors.white,
                onPressed: _showSellerInfo,
                child: const Icon(Icons.add_business),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _bottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapArea() {
    if (mapStyleUrl.isEmpty || mapAttribution.isEmpty || mapAttributionUrl.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE8F1F3), Color(0xFFDCE8EE), Color(0xFFEAF0F5)],
          ),
        ),
        child: CustomPaint(
          painter: RoadPatternPainter(),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 44, color: teal),
                  SizedBox(height: 12),
                  Text(
                    'خريطة الجزائر قيد الإعداد',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لن نعرض الخريطة قبل ضبط رابطها وإسناد مصدرها ورابط حقوقه. هذا يحمي التطبيق من عرض خريطة بلا ترخيص واضح.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        MapLibreMap(
          styleString: mapStyleUrl,
          initialCameraPosition: const CameraPosition(
            target: LatLng(28.0, 1.65),
            zoom: 4.2,
          ),
          compassEnabled: true,
          myLocationEnabled: false,
        ),
        Positioned(
          right: 8,
          bottom: 205,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final uri = Uri.tryParse(mapAttributionUrl);
                if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Text(
                  mapAttribution,
                  style: const TextStyle(fontSize: 10, color: navy, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Material(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: const TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن محل أو منتج أو مدينة...',
          prefixIcon: Icon(Icons.search, color: teal),
          suffixIcon: Icon(Icons.tune, color: navy),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _sellerChip() {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _showSellerInfo,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, color: Colors.white, size: 18),
              SizedBox(width: 7),
              Text(
                'أنا بائع',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'اكتشف الجزائر',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navy),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('كل التصنيفات')),
            ],
          ),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                CategoryItem(icon: Icons.shopping_basket, label: 'غذائيات'),
                CategoryItem(icon: Icons.local_pharmacy, label: 'صيدليات'),
                CategoryItem(icon: Icons.restaurant, label: 'مطاعم'),
                CategoryItem(icon: Icons.checkroom, label: 'ملابس'),
                CategoryItem(icon: Icons.phone_iphone, label: 'إلكترونيات'),
                CategoryItem(icon: Icons.build, label: 'قطع غيار'),
              ],
            ),
          ),
          Row(
            children: [
              NavItem(icon: Icons.map_outlined, label: 'الخريطة', selected: selectedTab == 0, onTap: () => setState(() => selectedTab = 0)),
              NavItem(icon: Icons.favorite_border, label: 'المفضلة', selected: selectedTab == 1, onTap: () => setState(() => selectedTab = 1)),
              NavItem(icon: Icons.storefront_outlined, label: 'محلاتي', selected: selectedTab == 2, onTap: () => setState(() => selectedTab = 2)),
              NavItem(icon: Icons.person_outline, label: 'حسابي', selected: selectedTab == 3, onTap: () => setState(() => selectedTab = 3)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'خريطة البيانات: OpenStreetMap — ODbL',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSellerInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, color: teal, size: 42),
            SizedBox(height: 12),
            Text('مساحة البائع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: navy)),
            SizedBox(height: 8),
            Text(
              'قريباً: إنشاء حساب البائع، تثبيت موقع المحل، وإضافة المنتجات والأسعار.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  const CategoryItem({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(color: const Color(0xFFE8F7F5), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: teal),
          ),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, style: const TextStyle(fontSize: 11, color: navy)),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({super.key, required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? teal : const Color(0xFF8190A5);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class RoadPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFB8C9D0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paths = <Path>[
      Path()..moveTo(-20, size.height * .25)..cubicTo(size.width * .25, size.height * .12, size.width * .45, size.height * .42, size.width + 30, size.height * .20),
      Path()..moveTo(-20, size.height * .70)..cubicTo(size.width * .25, size.height * .55, size.width * .62, size.height * .86, size.width + 20, size.height * .62),
      Path()..moveTo(size.width * .22, -20)..cubicTo(size.width * .34, size.height * .3, size.width * .12, size.height * .62, size.width * .42, size.height + 20),
      Path()..moveTo(size.width * .76, -20)..cubicTo(size.width * .58, size.height * .3, size.width * .92, size.height * .58, size.width * .68, size.height + 20),
    ];

    for (final path in paths) {
      canvas.drawPath(path, road);
      canvas.drawPath(path, center);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
