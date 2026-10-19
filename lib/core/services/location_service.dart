import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String? errorMessage;

  LocationResult.success(this.position)
      : isSuccess = true,
        errorMessage = null;

  LocationResult.failure(this.errorMessage)
      : isSuccess = false,
        position = null;
}

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Request current GPS location with high accuracy
  Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.failure(
          'O serviço de GPS está desativado no aparelho. Por favor, ative a localização nas configurações.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.failure(
            'Permissão de localização negada pelo usuário.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.failure(
          'Permissão de localização permanentemente negada. Abra as configurações do aplicativo para autorizar.',
        );
      }

      // First try to get last known position for instant responsiveness
      Position? position = await Geolocator.getLastKnownPosition();

      // Request precise high-accuracy fix using LocationSettings
      try {
        final locationSettings = LocationSettings(
          accuracy: AppConfig.gpsAccuracy,
          timeLimit: AppConfig.gpsTimeoutDuration,
        );
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      } catch (e) {
        // If timeout and we had last known position, fallback to it
        if (position == null) {
          return LocationResult.failure(
            'Tempo limite esgotado ao buscar sinal GPS. Verifique se você está em local aberto.',
          );
        }
      }

      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.failure('Erro ao obter localização GPS: $e');
    }
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app permission settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
