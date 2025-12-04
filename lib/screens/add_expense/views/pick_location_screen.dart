import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class PickLocationScreen extends StatefulWidget {
  final LatLng initialLocation;

  const PickLocationScreen({super.key, required this.initialLocation});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng? pickedLocation;
  GoogleMapController? _mapController;
  Marker? _marker;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
    } else {
      // Optionally show a dialog if denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  void _selectLocation(LatLng position) {
    if (pickedLocation == position) return;

    setState(() {
      pickedLocation = position;
      _marker = Marker(markerId: const MarkerId('picked'), position: position);
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    if (_marker != null) return {_marker!};
    return {
      Marker(markerId: const MarkerId('initial'), position: widget.initialLocation)
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: pickedLocation == null
                ? null
                : () => Navigator.pop(context, pickedLocation),
          ),
        ],
      ),
      body: _locationPermissionGranted
          ? GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation,
          zoom: 16,
        ),
        onMapCreated: (controller) => _mapController = controller,
        onTap: _selectLocation,
        markers: _buildMarkers(),
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        scrollGesturesEnabled: true,
      )
          : const Center(child: Text("Waiting for location permission...")),
    );
  }
}
