import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';

enum GpsAccuracyQuality {
  excellent, // < 5 meters
  good,      // 5 - 10 meters
  moderate,  // 10 - 20 meters
  poor,      // > 20 meters
  unknown,
}

class LocationState {
  final bool isLoading;
  final Position? position;
  final String? errorMessage;
  final bool isManualOverride;

  const LocationState({
    this.isLoading = false,
    this.position,
    this.errorMessage,
    this.isManualOverride = false,
  });

  LocationState copyWith({
    bool? isLoading,
    Position? position,
    String? errorMessage,
    bool? isManualOverride,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      errorMessage: errorMessage,
      isManualOverride: isManualOverride ?? this.isManualOverride,
    );
  }

  GpsAccuracyQuality get accuracyQuality {
    if (position == null) return GpsAccuracyQuality.unknown;
    final acc = position!.accuracy;
    if (acc <= 5) return GpsAccuracyQuality.excellent;
    if (acc <= 10) return GpsAccuracyQuality.good;
    if (acc <= 20) return GpsAccuracyQuality.moderate;
    return GpsAccuracyQuality.poor;
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier({LocationService? locationService})
      : _locationService = locationService ?? LocationService.instance,
        super(const LocationState());

  Future<void> fetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _locationService.getCurrentLocation();

    if (result.isSuccess && result.position != null) {
      state = LocationState(
        isLoading: false,
        position: result.position,
        isManualOverride: false,
      );
    } else {
      state = LocationState(
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Não foi possível obter a localização GPS.',
      );
    }
  }

  void setManualPosition({
    required double latitude,
    required double longitude,
    double? altitude,
    double accuracy = 1.0,
  }) {
    final manualPos = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: altitude ?? 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    state = LocationState(
      isLoading: false,
      position: manualPos,
      isManualOverride: true,
      errorMessage: null,
    );
  }

  void setPosition(Position pos) {
    state = LocationState(
      isLoading: false,
      position: pos,
      isManualOverride: false,
    );
  }

  void reset() {
    state = const LocationState();
  }
}

final locationProvider =
    StateNotifierProvider.autoDispose<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
