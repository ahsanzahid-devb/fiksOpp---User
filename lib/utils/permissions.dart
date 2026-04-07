import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'constant.dart';

class Permissions {
  static PermissionHandlerPlatform get _handler =>
      PermissionHandlerPlatform.instance;

  /// iOS: [Permission.location] can tie into Always vs When-In-Use and confuse the
  /// system dialog. Dashboard flows only need When-In-Use.
  static Permission get _dashboardLocationPermission =>
      isIOS ? Permission.locationWhenInUse : Permission.location;

  static Future<bool> isLocationPermanentlyDenied() async {
    return _dashboardLocationPermission.isPermanentlyDenied;
  }

  static Future<bool> hasLocationWhenInUseGranted() async {
    return _dashboardLocationPermission.isGranted;
  }

  /// Location only — for dashboard / nearby services. Does **not** open system
  /// Settings (avoids repeated redirects when Home tab is recreated).
  static Future<bool> requestLocationWhenInUseForServices() async {
    final perm = _dashboardLocationPermission;
    final status = await perm.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final next = await perm.request();
    return next.isGranted;
  }

  static Future<bool> cameraFilesAndLocationPermissionsGranted() async {
    Future<bool> requestCameraAndLocation() async {
      final Map<Permission, PermissionStatus> statuses =
          await _handler.requestPermissions([
        Permission.camera,
        _dashboardLocationPermission,
      ]);
      return statuses.values.every((s) => s == PermissionStatus.granted);
    }

    if (!getBoolAsync(PERMISSION_STATUS)) {
      return requestCameraAndLocation();
    }

    // [PERMISSION_STATUS] can be true while the user later revoked access in Settings.
    final cam = await Permission.camera.status;
    final loc = await _dashboardLocationPermission.status;
    if (cam.isGranted && loc.isGranted) return true;
    if (cam.isPermanentlyDenied || loc.isPermanentlyDenied) return false;
    return requestCameraAndLocation();
  }
}

/// Only for Location (legacy); prefer [Permissions.requestLocationWhenInUseForServices].
class LocationPermissions {
  static PermissionHandlerPlatform get _handler =>
      PermissionHandlerPlatform.instance;

  static Future<bool> locationPermissionsGranted() async {
    Future<bool> requestLocation() async {
      final Map<Permission, PermissionStatus> statuses =
          await _handler.requestPermissions([
        Permissions._dashboardLocationPermission,
      ]);
      return statuses.values.every((s) => s == PermissionStatus.granted);
    }

    if (!getBoolAsync(PERMISSION_STATUS)) {
      return requestLocation();
    }

    final loc = await Permissions._dashboardLocationPermission.status;
    if (loc.isGranted) return true;
    if (loc.isPermanentlyDenied) return false;
    return requestLocation();
  }
}
