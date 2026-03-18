import 'package:flutter/material.dart';
import '../../data/models/tech_exercise_model.dart';

/// A self-contained card for entering one technical exercise's data.
class TechExerciseCard extends StatelessWidget {
  final int index;
  final TextEditingController nameCtrl;
  final TextEditingController seriesCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController metricCtrl;
  final TextEditingController restCtrl;
  final VoidCallback onRemove;

  const TechExerciseCard({
    super.key,
    required this.index,
    required this.nameCtrl,
    required this.seriesCtrl,
    required this.repsCtrl,
    required this.metricCtrl,
    required this.restCtrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ejercicio #${index + 1} · Técnica',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.tertiary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.error),
                  onPressed: onRemove,
                  tooltip: 'Eliminar ejercicio',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildField(nameCtrl, 'Nombre del ejercicio', Icons.directions_run),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildField(
                        seriesCtrl, 'Series', Icons.format_list_numbered,
                        isNumber: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(repsCtrl, 'Reps', Icons.looks_one,
                        isNumber: true)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildField(
                        metricCtrl, 'Métrica principal', Icons.show_chart,
                        isDecimal: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(
                        restCtrl, 'Descanso (s)', Icons.timer_outlined,
                        isNumber: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
              ? TextInputType.number
              : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  /// Builds a [TechExerciseModel] from the current field values.
  TechExerciseModel toModel() {
    return TechExerciseModel(
      orden: index + 1,
      nombreEjercicio: nameCtrl.text.trim(),
      series: int.tryParse(seriesCtrl.text) ?? 1,
      repeticiones: int.tryParse(repsCtrl.text) ?? 0,
      metricaPrincipal: double.tryParse(metricCtrl.text) ?? 0.0,
      descansoSegundos: int.tryParse(restCtrl.text) ?? 60,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    seriesCtrl.dispose();
    repsCtrl.dispose();
    metricCtrl.dispose();
    restCtrl.dispose();
  }
}
