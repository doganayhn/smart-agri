import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../providers/field_provider.dart';

class AddFieldScreen extends ConsumerStatefulWidget {
  const AddFieldScreen({super.key});

  @override
  ConsumerState<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends ConsumerState<AddFieldScreen> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  
  double? _selectedLat;
  double? _selectedLng;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final sizeStr = _sizeController.text.trim();

    if (name.isEmpty || sizeStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and size')),
      );
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a field location on the map')),
      );
      return;
    }

    final sizeSqm = double.tryParse(sizeStr);

    if (sizeSqm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Size must be a valid number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/v1/fields', data: {
        'name': name,
        'latitude': _selectedLat!,
        'longitude': _selectedLng!,
        'sizeSqm': sizeSqm,
        'visualId': 'VALLEY',
      });

      // Refresh list
      await ref.read(fieldNotifierProvider.notifier).loadFields();
      
      if (mounted) {
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data['message'] ?? 'Failed to add field';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Field')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Field Name',
                  prefixIcon: Icon(Icons.eco),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size (sq meters)',
                  prefixIcon: Icon(Icons.aspect_ratio),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(
                  _selectedLat == null
                      ? 'Tap to pick location on map'
                      : '${_selectedLat!.toStringAsFixed(4)}° N, ${_selectedLng!.toStringAsFixed(4)}° E',
                  style: TextStyle(
                    color: _selectedLat == null ? Colors.grey : Colors.green[700],
                    fontWeight: _selectedLat == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                tileColor: Colors.white,
                onTap: () async {
                  final result = await context.push<(double, double)>('/map-picker');
                  if (result != null) {
                    setState(() {
                      _selectedLat = result.$1;
                      _selectedLng = result.$2;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56, // Touch target guideline
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Field', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
