import 'dart:async';
import 'package:cogni_anchor/data/services/pair_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverLiveMapScreen extends StatefulWidget {
  const CaregiverLiveMapScreen({super.key});

  @override
  State<CaregiverLiveMapScreen> createState() => _CaregiverLiveMapScreenState();
}

class _CaregiverLiveMapScreenState extends State<CaregiverLiveMapScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription? _locationSubscription;

  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _listenToLiveLocation();
  }

  void _listenToLiveLocation() {
    final pairId = PairContext.pairId;

    if (pairId == null) {
      debugPrint(" No paired patient");
      return;
    }

    _locationSubscription = _client
        .from('live_location')
        .stream(primaryKey: ['patient_user_id'])
        .eq('pair_id', pairId)
        .listen((rows) {
          if (rows.isEmpty) {
            debugPrint(" No live location rows yet");
            return;
          }

          debugPrint(" live_location rows: $rows");

          final row = rows.first;

          final lat = row['latitude'] as double?;
          final lng = row['longitude'] as double?;

          if (lat == null || lng == null) return;

          final newPosition = LatLng(lat, lng);

          setState(() {
            _currentLocation = newPosition;
          });

          _mapController.move(newPosition, 16);
        });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Patient Location"),
        backgroundColor: const Color(0xFFFF653A),
      ),
      body: _currentLocation == null
          ? const Center(
              child: Text(
                "Waiting for patient location...",
                style: TextStyle(fontSize: 16),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentLocation!,
                zoom: 16,
                interactiveFlags:
                    InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.cogni_anchor',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50,
                      height: 50,
                      point: _currentLocation!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
