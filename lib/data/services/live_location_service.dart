import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LiveLocationService {
  static final LiveLocationService instance = LiveLocationService._();
  LiveLocationService._();

  StreamSubscription<Position>? _sub;
  final SupabaseClient _client = Supabase.instance.client;

  bool get isRunning => _sub != null;

  Future<void> start() async {
    if (_sub != null) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "CogniAnchor is sharing location",
          notificationText: "Location is being shared with caregiver",
          enableWakeLock: true,
        ),
      ),
    ).listen((pos) async {
      debugPrint(' POSITION RECEIVED: ${pos.latitude}, ${pos.longitude}');

      final userId = _client.auth.currentUser!.id;

      final pair = await _client
          .from('pairs')
          .select('id')
          .eq('patient_user_id', userId)
          .single();

      final pairId = pair['id'];

      await _client.from('live_location').upsert(
        {
          'pair_id': pairId, 
          'patient_user_id': userId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
        onConflict: 'patient_user_id',
      );
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
