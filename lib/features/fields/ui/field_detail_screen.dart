import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/field_model.dart';
import '../providers/field_provider.dart';
import '../../visuals/animations/animated_field_visual.dart';

class FieldDetailScreen extends ConsumerStatefulWidget {
  final String fieldId; // From GoRouter params

  const FieldDetailScreen({super.key, required this.fieldId});

  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // Attempt to find the field from state
    final fields = ref.watch(fieldNotifierProvider).fields;
    final field = fields.firstWhere(
      (f) => f.id == widget.fieldId,
      orElse: () => FieldModel(
        id: 'unknown',
        name: 'Field Not Found',
        latitude: 0,
        longitude: 0,
        sizeSqm: 0,
        visualId: 'VALLEY',
      ),
    );

    if (field.id == 'unknown') {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Field could not be loaded.'),
              TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(field.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Edit field logic
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Half: Visual Animation Core
            Expanded(
              flex: 5,
              child: _buildVisualSection(field),
            ),
            
            // Bottom Half: Data & Actions
            Expanded(
              flex: 4,
              child: _buildDataSection(field),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualSection(FieldModel field) {
    return Container(
      color: Colors.blueGrey[50], // Sky/background color
      width: double.infinity,
      child: AnimatedFieldVisual(
        visualId: field.visualId,
        recommendationStatus: field.recommendationStatus,
        isRaining: field.recommendationStatus == 'WAIT',
      ),
    );
  }

  Widget _buildDataSection(FieldModel field) {
    final isLoading = ref.watch(fieldNotifierProvider).isLoading;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recommendation Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: _getColorForStatus(field.recommendationStatus).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getColorForStatus(field.recommendationStatus).withAlpha((0.5 * 255).round()),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(field.recommendationStatus),
                  color: _getColorForStatus(field.recommendationStatus),
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(field.recommendationStatus),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _getColorForStatus(field.recommendationStatus),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusMessage(field.recommendationStatus),
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Current Weather Data (Placeholder data until provider linked)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherStat(Icons.thermostat, '32°C', 'Temp'),
              _buildWeatherStat(Icons.water_drop, '20%', 'Humidity'),
              _buildWeatherStat(Icons.umbrella, '0mm', 'Rain (24h)'),
            ],
          ),

          const Spacer(),

          // Main Action Button (In Thumb Zone)
          SizedBox(
            height: 64, // Large touch target for crucial action
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : () async {
                try {
                  // Call the new notifier method, hardcoding 50 liters for MVP
                  await ref.read(fieldNotifierProvider.notifier)
                      .logIrrigation(field.id, 50.0);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Irrigation logged successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')), 
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: isLoading 
                  ? const SizedBox(
                      width: 24, height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.water, size: 28),
              label: Text(
                isLoading ? 'Logging...' : 'I Watered This',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.blueGrey),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'IRRIGATE': return Colors.red;
      case 'WAIT': return Colors.orange;
      case 'GOOD': default: return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'IRRIGATE': return Icons.warning_amber_rounded;
      case 'WAIT': return Icons.access_time;
      case 'GOOD': default: return Icons.check_circle_outline;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'IRRIGATE': return 'Watering Needed';
      case 'WAIT': return 'Hold Off Irrigation';
      case 'GOOD': default: return 'Conditions Optimal';
    }
  }

  String _getStatusMessage(String status) {
    // In final implementation, this should come from the recommendation reason string
    switch (status) {
      case 'IRRIGATE': return 'Conditions are dry and no rain is expected.';
      case 'WAIT': return 'It looks dry, but rain is expected soon.';
      case 'GOOD': default: return 'Soil moisture and weather conditions look good.';
    }
  }
}
