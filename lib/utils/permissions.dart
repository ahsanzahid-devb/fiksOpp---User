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
    if (!getBoolAsync(PERMISSION_STATUS)) {
      final Map<Permission, PermissionStatus> statuses =
          await _handler.requestPermissions([
        Permission.camera,
        _dashboardLocationPermission,
      ]);

      final allGranted =
          statuses.values.every((s) => s == PermissionStatus.granted);
      return allGranted;
    }

    return true;
  }
}

/// Only for Location (legacy); prefer [Permissions.requestLocationWhenInUseForServices].
class LocationPermissions {
  static PermissionHandlerPlatform get _handler =>
      PermissionHandlerPlatform.instance;

  static Future<bool> locationPermissionsGranted() async {
    if (!getBoolAsync(PERMISSION_STATUS)) {
      final Map<Permission, PermissionStatus> statuses =
          await _handler.requestPermissions([
        Permissions._dashboardLocationPermission,
      ]);

      final allGranted =
          statuses.values.every((s) => s == PermissionStatus.granted);
      return allGranted;
    }

    return true;
  }
}
