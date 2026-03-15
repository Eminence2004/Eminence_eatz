import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = ApiConstants.baseUrl;

  static const LatLng _centerLocation = LatLng(5.6037, -0.1870);

  String _aiEta = "Connecting to Server...";
  String _trafficStatus = "Analyzing routes...";
  Color _trafficColor = Colors.grey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getRealEtaFromBackend();
  }

  Future<void> _getRealEtaFromBackend() async {
    try {
      String restaurantAddress = "Maxbite, Winneba";
      String userAddress = "UEW North Campus";

      final response = await http.post(
        Uri.parse('$baseUrl/track-order/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': restaurantAddress,
          'destination': userAddress,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _aiEta = data['eta'];
            _trafficStatus = "${data['traffic_status']} - via Google AI";

            if (data['traffic_status'] == "Heavy") {
              _trafficColor = Colors.red;
            } else if (data['traffic_status'] == "Moderate") {
              _trafficColor = Colors.orange;
            } else {
              _trafficColor = Colors.green;
            }
            _isLoading = false;
          });

          _showAiBotMessage("Route calculated! ETA is $_aiEta.");
        }
      } else {
        throw "Server Error";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiEta = "Unavailable";
          _trafficStatus = "Connection Failed";
          _isLoading = false;
        });
      }
    }
  }

  void _showAiBotMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.smart_toy, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Track Order #${widget.orderId}")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _centerLocation, zoom: 14.0),
            markers: {
              Marker(
                markerId: const MarkerId("restaurant"),
                position: _centerLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Estimated Arrival", style: TextStyle(color: Colors.grey)),
                          _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_aiEta, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _trafficColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(Icons.traffic, size: 16, color: _trafficColor),
                            const SizedBox(width: 5),
                            Text(_trafficStatus, style: TextStyle(color: _trafficColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}