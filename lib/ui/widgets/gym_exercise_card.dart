import 'package:flutter/material.dart';
import '../../data/models/gym_exercise_model.dart';

/// A self-contained card for entering one gym exercise's data.
/// Calls [onRemove] when the user deletes it.
class GymExerciseCard extends StatelessWidget {
  final int index;
  final TextEditingController nameCtrl;
  final TextEditingController seriesCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController rirCtrl;
  final TextEditingController restCtrl;
  final VoidCallback onRemove;

  const GymExerciseCard({
    super.key,
    required this.index,
    required this.nameCtrl,
    required this.seriesCtrl,
    required this.repsCtrl,
    required this.weightCtrl,
    required this.rirCtrl,
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
            // Card header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ejercicio #${index + 1} · Gimnasio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
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
            _buildField(nameCtrl, 'Nombre del ejercicio', Icons.fitness_center),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildField(seriesCtrl, 'Series', Icons.repeat,
                        isNumber: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(repsCtrl, 'Reps', Icons.looks_one,
                        isNumber: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(
                        weightCtrl, 'Peso (kg)', Icons.monitor_weight_outlined,
                        isDecimal: true)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildField(rirCtrl, 'RIR', Icons.speed,
                        isNumber: true)),
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

  /// Builds a [GymExerciseModel] from the current field values.
  GymExerciseModel toModel() {
    return GymExerciseModel(
      orden: index + 1,
      nombreEjercicio: nameCtrl.text.trim(),
      series: int.tryParse(seriesCtrl.text) ?? 0,
      repeticiones: int.tryParse(repsCtrl.text) ?? 0,
      pesoKg: double.tryParse(weightCtrl.text) ?? 0.0,
      rir: int.tryParse(rirCtrl.text) ?? 0,
      descansoSegundos: int.tryParse(restCtrl.text) ?? 60,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    seriesCtrl.dispose();
    repsCtrl.dispose();
    weightCtrl.dispose();
    rirCtrl.dispose();
    restCtrl.dispose();
  }
}
