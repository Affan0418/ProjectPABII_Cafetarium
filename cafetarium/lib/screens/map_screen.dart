import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafetarium/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final bool isPickingLocation;
  final bool showBackButton;

  const MapScreen({
    super.key,
    this.isPickingLocation = false,
    this.showBackButton = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng selectedLocation = const LatLng(-2.9761, 104.7754);
  String searchQuery = '';

  static const Color primaryBrown = Color(0xff9b6a43);
  static const Color lightBgColor = Color(0xfff3e8ec);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (!widget.isPickingLocation) return;

    setState(() {
      selectedLocation = latLng;
    });
  }

  void _selectLocation() {
    Navigator.pop(context, {
      'latitude': selectedLocation.latitude,
      'longitude': selectedLocation.longitude,
    });
  }

  void _moveToCafe(LatLng point) {
    mapController.move(point, 17);
    FocusScope.of(context).unfocus();

    setState(() {
      searchController.clear();
      searchQuery = '';
    });
  }

  void _showCafeBottomSheet({
    required String cafeId,
    required String name,
    required double rating,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color sheetColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final Color cardIconBg =
        isDark ? const Color(0xff2A2A2A) : primaryBrown.withOpacity(0.12);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cardIconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_cafe,
                  color: primaryBrown,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(cafeId: cafeId),
                    ),
                  );
                },
                child: const Text(
                  'Detail',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _buildCafeMarker(QueryDocumentSnapshot doc) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final data = doc.data() as Map<String, dynamic>;

    final double lat = (data['latitude'] ?? 0).toDouble();
    final double lng = (data['longitude'] ?? 0).toDouble();
    final String name = data['name'] ?? 'Cafe';
    final double rating = (data['rating'] ?? 0).toDouble();

    final point = LatLng(lat, lng);

    final Color markerBg = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final Color markerText = isDark ? Colors.white : Colors.black87;

    return Marker(
      point: point,
      width: 120,
      height: 72,
      child: GestureDetector(
        onTap: () {
          _showCafeBottomSheet(
            cafeId: doc.id,
            name: name,
            rating: rating,
          );
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: markerBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_cafe,
                color: primaryBrown,
                size: 28,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 105),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: markerBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: markerText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerLayer() {
    if (widget.isPickingLocation) {
      return MarkerLayer(
        markers: [
          Marker(
            point: selectedLocation,
            width: 70,
            height: 70,
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 58,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cafes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const MarkerLayer(markers: []);
        }

        final markers = snapshot.data!.docs.map((doc) {
          return _buildCafeMarker(doc);
        }).toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  Widget _buildTopSearchBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? Colors.white60 : Colors.black54;
    final Color borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    if (widget.isPickingLocation) {
      return Positioned(
        top: 14,
        left: 14,
        right: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app, color: primaryBrown),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap peta untuk memilih lokasi cafe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.2,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari cafe di map...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: hintColor,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: primaryBrown,
                  size: 22,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 50,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: primaryBrown,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (searchQuery.isNotEmpty) _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final Color borderColor = isDark ? Colors.white12 : Colors.transparent;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cafes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final cafes = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final description =
              (data['description'] ?? '').toString().toLowerCase();

          return name.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();

        if (cafes.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_off, color: primaryBrown),
                const SizedBox(width: 10),
                Text(
                  'Cafe tidak ditemukan',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: cafes.length,
            itemBuilder: (context, index) {
              final doc = cafes[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Cafe';
              final double lat = (data['latitude'] ?? 0).toDouble();
              final double lng = (data['longitude'] ?? 0).toDouble();
              final double rating = (data['rating'] ?? 0).toDouble();

              final point = LatLng(lat, lng);

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: primaryBrown,
                  child: Icon(
                    Icons.local_cafe,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(color: subTextColor),
                    ),
                  ],
                ),
                onTap: () {
                  _moveToCafe(point);
                  _showCafeBottomSheet(
                    cafeId: doc.id,
                    name: name,
                    rating: rating,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildZoomButtons() {
    return Positioned(
      right: 14,
      bottom: widget.isPickingLocation ? 105 : 24,
      child: Column(
        children: [
          _roundMapButton(
            icon: Icons.add,
            onTap: () {
              final camera = mapController.camera;
              mapController.move(camera.center, camera.zoom + 1);
            },
          ),
          const SizedBox(height: 10),
          _roundMapButton(
            icon: Icons.remove,
            onTap: () {
              final camera = mapController.camera;
              mapController.move(camera.center, camera.zoom - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _roundMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xff1E1E1E) : Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: primaryBrown,
          ),
        ),
      ),
    );
  }

  Widget _buildPickLocationButton() {
    if (!widget.isPickingLocation) return const SizedBox.shrink();

    return Positioned(
      left: 18,
      right: 18,
      bottom: 20,
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _selectLocation,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text(
            'Pilih Lokasi Ini',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 7,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (widget.isPickingLocation || !widget.showBackButton) return null;

    return AppBar(
      backgroundColor: primaryBrown,
      elevation: 0,
      title: const Text(
        'Cafe Terdekat',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xff121212) : lightBgColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selectedLocation,
                initialZoom: 15,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cafetarium',
                ),
                _buildMarkerLayer(),
              ],
            ),
            _buildTopSearchBar(),
            _buildZoomButtons(),
            _buildPickLocationButton(),
          ],
        ),
      ),
    );
  }
}