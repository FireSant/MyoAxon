import 'package:flutter/material.dart';
import 'vbt_analysis_screen.dart';

/// Pantalla de calibración VBT.
/// El usuario ingresa el diámetro real del disco y toca el disco en pantalla
/// para obtener su tamaño en píxeles → calcula la ratio px/m.
class VbtCalibrationScreen extends StatefulWidget {
  const VbtCalibrationScreen({super.key});

  @override
  State<VbtCalibrationScreen> createState() => _VbtCalibrationScreenState();
}

class _VbtCalibrationScreenState extends State<VbtCalibrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diameterController = TextEditingController(text: '0.45');

  // Tamaños de disco estándar (en metros)
  static const _presets = [
    ('5 kg  — 0.45 m', 0.45),
    ('10 kg — 0.45 m', 0.45),
    ('20 kg — 0.45 m', 0.45),
    ('25 kg — 0.45 m', 0.45),
    ('Técnico (15 kg) — 0.45 m', 0.45),
  ];

  @override
  void dispose() {
    _diameterController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    final double diameter =
        double.parse(_diameterController.text.replaceAll(',', '.'));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VbtAnalysisScreen(diskDiameterMeters: diameter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Calibración VBT'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ilustración
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFBAE6FD),
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: Color(0xFF0284C7),
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instrucción
                const Text(
                  'Diámetro del Disco',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa el diámetro real del disco que usarás como referencia. '
                  'La app calculará automáticamente la relación píxeles/metro.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),

                // Presets rápidos
                const Text(
                  'Selección rápida',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((p) {
                    return ActionChip(
                      label: Text(p.$1, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _diameterController.text = p.$2.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Input manual
                TextFormField(
                  controller: _diameterController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Diámetro (metros)',
                    hintText: 'ej. 0.45',
                    prefixIcon: Icon(Icons.straighten_rounded),
                    suffixText: 'm',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Campo requerido';
                    final v = double.tryParse(val.replaceAll(',', '.'));
                    if (v == null || v <= 0 || v > 1.0) {
                      return 'Ingresa un valor entre 0.01 y 1.00 m';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Tip de calibración
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Coloca el disco olímpico estándar (45 cm) en el suelo, '
                          'bien visible y paralelo a la cámara.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('Iniciar Análisis VBT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
