import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

/// Modal or screen that lets users pick their exact service or delivery location
/// using OpenStreetMap (100% free, no Google Maps API key needed)
class MapLocationPickerModal extends StatefulWidget {
  final LatLng? initialPosition;

  const MapLocationPickerModal({super.key, this.initialPosition});

  static Future<UserLocationResult?> show(BuildContext context, {LatLng? initialPosition}) {
    return showModalBottomSheet<UserLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapLocationPickerModal(initialPosition: initialPosition),
    );
  }

  @override
  State<MapLocationPickerModal> createState() => _MapLocationPickerModalState();
}

class _MapLocationPickerModalState extends State<MapLocationPickerModal> {
  late final MapController _mapController;
  late LatLng _selectedPoint;
  String _addressText = 'Detecting address...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = widget.initialPosition ?? LocationService.defaultLocation;
    _resolveAddress(_selectedPoint);
  }

  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _isLoading = true);
    final res = await LocationService.instance.getAddressFromCoordinates(point);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _addressText = res?.formattedAddress ?? 'Selected Location';
      });
    }
  }

  Future<void> _locateUser() async {
    setState(() => _isLoading = true);
    final res = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      if (res != null) {
        setState(() {
          _selectedPoint = res.position;
          _addressText = res.formattedAddress;
          _isLoading = false;
        });
        _mapController.move(res.position, 16.0);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access GPS. Please check location permissions.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map, color: primary),
                        SizedBox(width: 8),
                        Text(
                          'Pin Service / Delivery Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map View (OpenStreetMap)
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedPoint = point);
                      _resolveAddress(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: LocationService.geoapifyApiKey.isNotEmpty
                          ? 'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${LocationService.geoapifyApiKey}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.califnco.water',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
                          width: 46,
                          height: 46,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.redAccent,
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // GPS FAB
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'gps_fab',
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    onPressed: _locateUser,
                    child: const Icon(Icons.my_location),
                  ),
                ),

                // Tap hint overlay
                Positioned(
                  top: 12,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap anywhere on the map to pin exact address',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Address preview & confirmation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLoading
                          ? const Text('Loading address...', style: TextStyle(color: Colors.grey))
                          : Text(
                              _addressText,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final res = await LocationService.instance.getAddressFromCoordinates(_selectedPoint);
                    if (context.mounted) {
                      Navigator.pop(context, res);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
