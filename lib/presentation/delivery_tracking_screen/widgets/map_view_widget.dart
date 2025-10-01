import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MapViewWidget extends StatefulWidget {
  final Map<String, dynamic> deliveryData;
  final Map<String, dynamic> runnerData;
  final VoidCallback onCenterOnRunner;

  const MapViewWidget({
    Key? key,
    required this.deliveryData,
    required this.runnerData,
    required this.onCenterOnRunner,
  }) : super(key: key);

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    _createMarkers();
    _createRoute();
  }

  void _createMarkers() {
    final pickupLat = widget.deliveryData['pickupLatitude'] ?? 4.9031;
    final pickupLng = widget.deliveryData['pickupLongitude'] ?? 114.9398;
    final dropoffLat = widget.deliveryData['dropoffLatitude'] ?? 4.8903;
    final dropoffLng = widget.deliveryData['dropoffLongitude'] ?? 114.9421;
    final runnerLat = widget.runnerData['currentLatitude'] ?? 4.8967;
    final runnerLng = widget.runnerData['currentLongitude'] ?? 114.9410;

    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.deliveryData['pickupAddress'] ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(dropoffLat, dropoffLng),
        infoWindow: InfoWindow(
          title: 'Delivery Location',
          snippet: widget.deliveryData['dropoffAddress'] ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('runner'),
        position: LatLng(runnerLat, runnerLng),
        infoWindow: InfoWindow(
          title: widget.runnerData['name'] ?? 'Delivery Runner',
          snippet: 'Current location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  void _createRoute() {
    final pickupLat = widget.deliveryData['pickupLatitude'] ?? 4.9031;
    final pickupLng = widget.deliveryData['pickupLongitude'] ?? 114.9398;
    final dropoffLat = widget.deliveryData['dropoffLatitude'] ?? 4.8903;
    final dropoffLng = widget.deliveryData['dropoffLongitude'] ?? 114.9421;
    final runnerLat = widget.runnerData['currentLatitude'] ?? 4.8967;
    final runnerLng = widget.runnerData['currentLongitude'] ?? 114.9410;

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(runnerLat, runnerLng),
          LatLng(pickupLat, pickupLng),
          LatLng(dropoffLat, dropoffLng),
        ],
        color: AppTheme.lightTheme.colorScheme.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _fitMarkersInView();
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.runnerData['currentLatitude'] ?? 4.8967,
              widget.runnerData['currentLongitude'] ?? 114.9410,
            ),
            zoom: 14.0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: true,
          buildingsEnabled: true,
          indoorViewEnabled: true,
          mapType: MapType.normal,
        ),

        // Center on runner button
        Positioned(
          right: 4.w,
          bottom: 20.h,
          child: FloatingActionButton(
            onPressed: () {
              _centerOnRunner();
              widget.onCenterOnRunner();
            },
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            foregroundColor: AppTheme.lightTheme.colorScheme.primary,
            mini: true,
            child: CustomIconWidget(
              iconName: 'my_location',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
          ),
        ),

        // Emergency contact button
        Positioned(
          right: 4.w,
          bottom: 12.h,
          child: FloatingActionButton(
            onPressed: _showEmergencyContact,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            mini: true,
            child: CustomIconWidget(
              iconName: 'emergency',
              color: Colors.white,
              size: 5.w,
            ),
          ),
        ),

        // Map legend
        Positioned(
          top: 6.h,
          left: 4.w,
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(2.w),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('Pickup', Colors.green),
                SizedBox(height: 1.h),
                _buildLegendItem('Delivery', Colors.red),
                SizedBox(height: 1.h),
                _buildLegendItem('Runner', Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _centerOnRunner() {
    if (_mapController != null) {
      final runnerLat = widget.runnerData['currentLatitude'] ?? 4.8967;
      final runnerLng = widget.runnerData['currentLongitude'] ?? 114.9410;

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(runnerLat, runnerLng),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _fitMarkersInView() {
    if (_mapController != null && _markers.isNotEmpty) {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Emergency Support',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need immediate assistance with your delivery?',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              'Emergency Hotline: +673 123 4567',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Support Chat: Available 24/7',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to support chat
              Navigator.pushNamed(context, '/chat-screen');
            },
            child: Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
