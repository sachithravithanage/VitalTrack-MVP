import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  static const Color primary = Color(0xFF13C8EC);
  // static const Color accentOrange = Color(0xFFF97316);
  static const Color backgroundLight = Color(0xFFF6F8F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/appicon.png', // Your file path
                height: 30, // Change this value to your desired size
                width: 30,       // This tints the image orange
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text("VitalTrack", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(backgroundColor: backgroundLight),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for location in Sri Lanka...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: surfaceWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // _buildChip("All Diseases", isSelected: true),
                  _buildChip("Dengue",isSelected: true),
                  _buildChip("Leptospirosis"),
                  // _buildChip("Last 7 Days", hasDropdown: true),
                ],
              ),
            ),

            // Map Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: HeatmapCard(),
            ),

            // Density Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Density Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("View All")),
                ],
              ),
            ),

            _buildDistrictCard("Colombo District", "1,240 reported cases", "+12%", Colors.red),
            _buildDistrictCard("Jaffna District", "458 reported cases", "+2%", Colors.orange),
            _buildDistrictCard("Kandy District", "215 reported cases", "-5%", Colors.green),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(color: surfaceWhite,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, "Home"),
            _buildNavItem(Icons.map, "Map", isSelected: true),
            _buildNavItem(Icons.description_outlined, "Log"),
            _buildNavItem(Icons.person_outline, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool isSelected = false, bool hasDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Row(
          children: [
            Text(label),
            if (hasDropdown) const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
        backgroundColor: isSelected ? primary : surfaceWhite,
        labelStyle: TextStyle(
          color: isSelected ? surfaceWhite : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? primary : Colors.grey),
        Text(label, style: TextStyle(fontSize: 10, color: isSelected ? primary : Colors.grey)),
      ],
    );
  }

  Widget _buildDistrictCard(String title, String subtitle, String stats, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.trending_up, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(stats, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const Text("THIS WEEK", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class HeatmapCard extends StatefulWidget {
  const HeatmapCard({super.key});

  @override
  State<HeatmapCard> createState() => _HeatmapCardState();
}

class _HeatmapCardState extends State<HeatmapCard> {
  late List<DistrictData> _data;
  late MapShapeSource _shapeSource;

  @override
  void initState() {
    // 1. Data for all 25 Districts
    _data = const [
      DistrictData('Colombo', 2800), DistrictData('Gampaha', 1500),
      DistrictData('Kalutara', 800), DistrictData('Kandy', 950),
      DistrictData('Matale', 400), DistrictData('Nuwara Eliya', 200),
      DistrictData('Galle', 300), DistrictData('Matara', 350),
      DistrictData('Hambantota', 150), DistrictData('Jaffna', 600),
      DistrictData('Kilinochchi', 100), DistrictData('Mannar', 80),
      DistrictData('Vavuniya', 120), DistrictData('Mullaitivu', 60),
      DistrictData('Batticaloa', 450), DistrictData('Ampara', 500),
      DistrictData('Trincomalee', 350), DistrictData('Kurunegala', 1100),
      DistrictData('Puttalam', 700), DistrictData('Anuradhapura', 550),
      DistrictData('Polonnaruwa', 300), DistrictData('Badulla', 400),
      DistrictData('Monaragala', 250), DistrictData('Ratnapura', 900),
      DistrictData('Kegalle', 850),
    ];

    _shapeSource = MapShapeSource.asset(
      'assets/srilanka_25_districts.json',
      // IMPORTANT: Check your GeoJSON file's "properties" section.
      // If the district name is under "NAME_2", change this to "NAME_2".
      // If it's under "shapeName", use "shapeName".
      shapeDataField: 'shapeName',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].district,

      dataLabelMapper: (int index) => _data[index].district,

      shapeColorValueMapper: (int index) => _data[index].cases,

      // Color scale matching your uploaded image
      shapeColorMappers: [
        MapColorMapper(from: 0, to: 250, color:const Color(0xFFFEE5D9) , text: '< 250'),
        MapColorMapper(from: 251, to: 500, color: const Color(0xFFFCAE91), text: '≥ 250'),
        MapColorMapper(from: 501, to: 750, color: const Color(0xFFFB6A4A), text: '≥ 500'),
        MapColorMapper(from: 751, to: 1200, color: const Color(0xFFDE2D26), text: '≥ 750'),
        MapColorMapper(from: 1201, to: 2500, color: const Color(0xFFA50F15), text: '≥ 1,200'),
        MapColorMapper(from: 2501, to: 10000, color: const Color(0xFF67000D), text: '≥ 2,500'),
      ],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520, // Taller to fit the legend
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue "Ocean" background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Dengue Distribution Map",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: SfMaps(
              layers: [
                MapShapeLayer(
                  source: _shapeSource,
                  showDataLabels: true, // 1. Enable labels

                  // 2. Customize how the labels look
                  dataLabelSettings: const MapDataLabelSettings(
                    textStyle: TextStyle(
                      color: Colors.black, // Use white if the heatmap is very dark
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    // This hides labels if they are too big for a small district
                    overflowMode: MapLabelOverflow.visible,
                  ),

                  strokeColor: Colors.white,
                  strokeWidth: 0.5,
                  legend: const MapLegend(
                    MapElement.shape,
                    position: MapLegendPosition.bottom,
                    iconType: MapIconType.rectangle,
                  ),
                ),
                // MapShapeLayer(
                //   source: _shapeSource,
                //   showDataLabels: false,
                //   strokeColor: Colors.white,
                //   strokeWidth: 0.5,
                //   legend: const MapLegend(
                //     MapElement.shape,
                //     position: MapLegendPosition.bottom,
                //     padding: EdgeInsets.all(10),
                //     iconType: MapIconType.rectangle,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DistrictData {
  const DistrictData(this.district, this.cases);
  final String district;
  final double cases;
}

// class HeatmapCard extends StatelessWidget {
//   const HeatmapCard({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 400,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         color: Colors.grey.shade200,
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Stack(
//         children: [
//           // Use a real Map Image URL or GoogleMap widget here
//           Image.network(
//             'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Sri_Lanka_location_map.svg/800px-Sri_Lanka_location_map.svg.png',
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           ),
//           // Heatmap Overlay
//           CustomPaint(
//             painter: HeatPainter(),
//             size: Size.infinite,
//           ),
//           // Legend
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("OUTBREAK DENSITY", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
//                   SizedBox(height: 4),
//                   _LegendItem(color: Colors.red, label: "High Risk"),
//                   _LegendItem(color: Colors.orange, label: "Medium"),
//                   _LegendItem(color: Colors.yellow, label: "Low Cases"),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 4),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class HeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Colombo Hotspot
    paint.color = Colors.red.withOpacity(0.4);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.7), 40, paint);
    paint.color = Colors.red.withOpacity(0.6);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.7), 15, paint);

    // Jaffna Hotspot
    paint.color = Colors.orange.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.15), 30, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}