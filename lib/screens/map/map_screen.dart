import 'package:fiksOpp/component/back_widget.dart';
import 'package:fiksOpp/component/loader_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/services/location_service.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../utils/constant.dart';

class MapScreen extends StatefulWidget {
  final double? latLong;
  final double? latitude;

  MapScreen({this.latLong, this.latitude});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late CameraPosition _initialLocation;
  GoogleMapController? _mapController;
  LatLng? _pendingCameraTarget;
  double _pendingZoom = 18;

  String? mapStyle;

  final destinationAddressController = TextEditingController();
  final destinationAddressFocusNode = FocusNode();

  Set<Marker> markers = {};

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    double lat = 59.9139;
    double lng = 10.7522;
    final wLat = widget.latitude;
    final wLng = widget.latLong;
    if (wLat != null && wLng != null && wLat != 0 && wLng != 0) {
      lat = wLat;
      lng = wLng;
    }
    _initialLocation = CameraPosition(target: LatLng(lat, lng), zoom: 14);

    if (appStore.isDarkMode) {
      DefaultAssetBundle.of(context)
          .loadString('assets/json/map_style_dark.json')
          .then((value) {
        mapStyle = value;
        setState(() {});
      }).catchError(onError);
    }
    afterBuildCreated(() => _loadInitialLocation());
  }

  Future<void> _animateTo(LatLng target, double zoom) async {
    final c = _mapController;
    if (c != null) {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } else {
      _pendingCameraTarget = target;
      _pendingZoom = zoom;
    }
  }

  Future<void> _loadInitialLocation() async {
    final ok = await Permissions.requestLocationWhenInUseForServices();
    if (!ok) {
      if (mounted) {
        if (await Permissions.isLocationPermanentlyDenied()) {
          toast(language.lblLocationPermissionDeniedPermanently);
        } else {
          toast(language.lblLocationPermissionDenied);
        }
      }
      return;
    }

    appStore.setLoading(true);
    try {
      final position = await getUserLocationPosition();
      final addr = await buildFullAddressFromLatLong(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      setState(() {
        destinationAddressController.text = addr;
        markers = {
          Marker(
            markerId: const MarkerId('map_pin'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: addr),
            icon: BitmapDescriptor.defaultMarker,
          ),
        };
      });
      await _animateTo(LatLng(position.latitude, position.longitude), 18);
    } catch (e) {
      if (mounted) toast(e.toString());
    } finally {
      if (mounted) appStore.setLoading(false);
    }
  }

  Future<void> _handleTap(LatLng point) async {
    appStore.setLoading(true);
    try {
      markers = {
        Marker(
          markerId: MarkerId(point.toString()),
          position: point,
          infoWindow: const InfoWindow(),
          icon: BitmapDescriptor.defaultMarker,
        ),
      };

      final text =
          await buildFullAddressFromLatLong(point.latitude, point.longitude);
      if (!mounted) return;
      destinationAddressController.text = text;
      setState(() {});
    } catch (e) {
      if (mounted) toast(e.toString());
    } finally {
      if (mounted) appStore.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBarWidget(
        language.chooseYourLocation,
        backWidget: BackWidget(),
        color: primaryColor,
        elevation: 0,
        textColor: white,
        textSize: APP_BAR_TEXT_SIZE,
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            markers: Set<Marker>.from(markers),
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            style: mapStyle,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              final pending = _pendingCameraTarget;
              if (pending != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: pending, zoom: _pendingZoom),
                  ),
                );
                _pendingCameraTarget = null;
              }
            },
            onTap: _handleTap,
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ClipOval(
                  child: Material(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    child: InkWell(
                      splashColor: context.primaryColor.withValues(alpha: 0.8),
                      child: const SizedBox(
                          width: 50, height: 50, child: Icon(Icons.add)),
                      onTap: () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ClipOval(
                  child: Material(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    child: InkWell(
                      splashColor: context.primaryColor.withValues(alpha: 0.8),
                      child: const SizedBox(
                          width: 50, height: 50, child: Icon(Icons.remove)),
                      onTap: () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                  ),
                ),
              ],
            ).paddingLeft(10),
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipOval(
                  child: Material(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    child:
                        const Icon(Icons.my_location, size: 25).paddingAll(10),
                  ),
                ).paddingRight(8).onTap(() async {
                  appStore.setLoading(true);
                  try {
                    final value = await getUserLocationPosition();
                    if (!mounted) return;
                    await _animateTo(
                        LatLng(value.latitude, value.longitude), 18);
                    await _handleTap(LatLng(value.latitude, value.longitude));
                  } catch (e) {
                    if (mounted) toast(e.toString());
                  } finally {
                    if (mounted) appStore.setLoading(false);
                  }
                }),
                8.height,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppTextField(
                      textFieldType: TextFieldType.MULTILINE,
                      controller: destinationAddressController,
                      focus: destinationAddressFocusNode,
                      textStyle: primaryTextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white
                              : Colors.black),
                      decoration: inputDecoration(context,
                              labelText: language.hintAddress)
                          .copyWith(
                              fillColor: appStore.isDarkMode
                                  ? Colors.black54
                                  : Colors.white70),
                    ),
                  ],
                ),
                8.height,
                AppButton(
                  width: context.width(),
                  height: 16,
                  color: primaryColor.withValues(alpha: 0.8),
                  text: language.setAddress.toUpperCase(),
                  textStyle: boldTextStyle(color: white, size: 12),
                  onTap: () {
                    if (destinationAddressController.text.isNotEmpty) {
                      finish(context, destinationAddressController.text);
                    } else {
                      toast(language.lblPickAddress);
                    }
                  },
                ),
                8.height,
              ],
            ).paddingAll(16),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
    );
  }
}
