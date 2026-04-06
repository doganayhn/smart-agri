import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'location_helper.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  double _lat = 39.9334;
  double _lng = 32.8597;
  Timer? _locationTimer;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _requestWebLocation() {
    if (kIsWeb) {
      requestWebLocationAsync();
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        final res = getWebLocationResultAsync();
        if (res != null) {
          timer.cancel();
          setState(() {
            _lat = res['lat']!;
            _lng = res['lng']!;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS only available on web in this version.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Field Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              context.pop((_lat, _lng));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Top 60%: Pixel Art Map Placeholder
          Expanded(
            flex: 60,
            child: Stack(
              children: [
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Canvas size estimate: width ~ MediaQuery, height ~ 60% of vertical
                      // Map ±5 degrees per full screen swipe
                      final dx = details.delta.dx / MediaQuery.of(context).size.width * (-5.0);
                      final dy = details.delta.dy / (MediaQuery.of(context).size.height * 0.6) * (5.0);
                      _lat = (_lat + dy).clamp(-90.0, 90.0);
                      _lng = (_lng + dx).clamp(-180.0, 180.0);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.green[100],
                    child: CustomPaint(
                      painter: _PixelMapPainter(),
                    ),
                  ),
                ),
                // Center Pin
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 48),
                      // Small shadow
                      SizedBox(
                        width: 12,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _requestWebLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use My Location'),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Bottom 40%: Data Card
          Expanded(
            flex: 40,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Latitude: ${_lat.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Longitude: ${_lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.pop((_lat, _lng)),
                      child: const Text('Confirm Location', style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid of light green/beige squares
    final paint1 = Paint()..color = const Color(0xFFC8E6C9); // Light green
    final paint2 = Paint()..color = const Color(0xFFE8F5E9); // Lighter green
    final paint3 = Paint()..color = const Color(0xFFFFF9C4); // Beige

    final gridSize = 40.0;
    for (double y = 0; y < size.height; y += gridSize) {
      for (double x = 0; x < size.width; x += gridSize) {
        final rand = (x * 3 + y * 7).toInt() % 3;
        final paint = rand == 0 ? paint1 : (rand == 1 ? paint2 : paint3);
        canvas.drawRect(Rect.fromLTWH(x, y, gridSize, gridSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
