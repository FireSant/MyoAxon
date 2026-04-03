import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exercise_records_provider.dart';
import '../charts/volume_line_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Progresión de Volumen Total',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                // Ahora usa el CardTheme definido en app_theme.dart
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: VolumeLineChart(records: records),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total de Series Registradas'),
                    Text(
                      '${records.length}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.construction,
                        size: 48,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(height: 12),
                    Text(
                      'Próximamente',
                      style: Theme.of(context)
                          .textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta sección está en desarrollo y estará disponible próximamente.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
