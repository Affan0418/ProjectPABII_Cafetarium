  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:latlong2/latlong.dart';

  class MapScreen extends StatefulWidget {
    final bool isPickingLocation;

    const MapScreen({
      super.key,
      this.isPickingLocation = false,
    });

    @override
    State<MapScreen> createState() => _MapScreenState();
  }

  class _MapScreenState extends State<MapScreen> {
    final MapController mapController = MapController();

    LatLng selectedLocation = const LatLng(-2.9761, 104.7754);

    static const Color primaryBrown = Color(0xff9b6a43);
    static const Color bgColor = Color(0xfff3e8ec);

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

    Marker _buildCafeMarker(Map<String, dynamic> data) {
      final double lat = (data['latitude'] ?? 0).toDouble();
      final double lng = (data['longitude'] ?? 0).toDouble();
      final String name = data['name'] ?? 'Cafe';

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 75,
        child: Column(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildMarkerLayer() {
      if (widget.isPickingLocation) {
        return MarkerLayer(
          markers: [
            Marker(
              point: selectedLocation,
              width: 55,
              height: 55,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
              ),
            ),
          ],
        );
      }

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cafes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MarkerLayer(markers: []);
          }

          if (!snapshot.hasData) {
            return const MarkerLayer(markers: []);
          }

          final cafes = snapshot.data!.docs;

          final markers = cafes.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildCafeMarker(data);
          }).toList();

          return MarkerLayer(markers: markers);
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          title: Text(
            widget.isPickingLocation ? 'Pilih Lokasi Cafe' : 'Map Cafe',
          ),
        ),
        body: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: selectedLocation,
            initialZoom: 15,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.cafetarium',
            ),
            _buildMarkerLayer(),
          ],
        ),
        bottomNavigationBar: widget.isPickingLocation
            ? Container(
                padding: const EdgeInsets.all(16),
                color: bgColor,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Pilih Lokasi Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      );
    }
  }