import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/field_provider.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<FieldState>(fieldNotifierProvider, (previous, next) {
      if (next.error != null && (previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final fieldState = ref.watch(fieldNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildBody(fieldState, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-field'),
        icon: const Icon(Icons.add),
        label: const Text('Add Field'),
      ),
    );
  }

  Widget _buildBody(FieldState state, WidgetRef ref) {
    if (state.isLoading && state.fields.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(fieldNotifierProvider.notifier).loadFields(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.fields.isEmpty) {
      return const Center(
        child: Text(
          'No fields yet.\nAdd one to start tracking!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fieldNotifierProvider.notifier).loadFields(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.82, // Tweak aspect ratio slightly for the extra text line
        ),
        itemCount: state.fields.length,
        itemBuilder: (context, index) {
          final field = state.fields[index];
          final color = _getColorForStatus(field.recommendationStatus);

          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {
                context.push('/field/${field.id}');
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: color, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              color.withAlpha((0.3 * 255).round()),
                              color.withAlpha((0.1 * 255).round()),
                            ],
                            radius: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco,
                            size: 48,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              field.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              field.activeCropName ?? 'Empty',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${field.sizeSqm} m²',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
}
