import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'constant.dart';

class Permissions {
  static PermissionHandlerPlatform get _handler =>
      PermissionHandlerPlatform.instance;

  /// Use Geolocator as the single source of truth for location so it stays in sync
  /// with [getUserLocation] / [getUserLocationPosition]. permission_handler alone
  /// can report "granted" while Geolocator still sees "denied" on some iOS builds.
  static Future<bool> isLocationPermanentlyDenied() async {
    return await Geolocator.checkPermission() ==
        LocationPermission.deniedForever;
  }

  static Future<bool> hasLocationWhenInUseGranted() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Location only — for dashboard / nearby services. Does **not** open system
  /// Settings (avoids repeated redirects when Home tab is recreated).
  static Future<bool> requestLocationWhenInUseForServices() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<bool> cameraFilesAndLocationPermissionsGranted() async {
    Future<bool> requestCameraAndLocation() async {
      final Map<Permission, PermissionStatus> statuses =
          await _handler.requestPermissions([
        Permission.camera,
      ]);
      final camOk = statuses[Permission.camera] == PermissionStatus.granted;
      if (!camOk) return false;
      return requestLocationWhenInUseForServices();
    }

    if (!getBoolAsync(PERMISSION_STATUS)) {
      return requestCameraAndLocation();
    }

    final cam = await Permission.camera.status;
    if (!cam.isGranted) {
      if (cam.isPermanentlyDenied) return false;
      return requestCameraAndLocation();
    }
    if (await hasLocationWhenInUseGranted()) return true;
    if (await isLocationPermanentlyDenied()) return false;
    return requestLocationWhenInUseForServices();
  }
}

/// Only for Location (legacy); prefer [Permissions.requestLocationWhenInUseForServices].
class LocationPermissions {
  static Future<bool> locationPermissionsGranted() async {
    if (!getBoolAsync(PERMISSION_STATUS)) {
      return Permissions.requestLocationWhenInUseForServices();
    }

    if (await Permissions.hasLocationWhenInUseGranted()) return true;
    if (await Permissions.isLocationPermanentlyDenied()) return false;
    return Permissions.requestLocationWhenInUseForServices();
  }
}
