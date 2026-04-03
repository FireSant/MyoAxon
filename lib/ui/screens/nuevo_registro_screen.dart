import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../data/models/gym_exercise_model.dart';
import '../../data/models/tech_exercise_model.dart';
import '../../data/models/session_model.dart';
import '../widgets/gym_exercise_card.dart';
import '../widgets/tech_exercise_card.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';

// --------------- Providers ---------------

final nuevoRegistroProvider =
    StateNotifierProvider.autoDispose<NuevoRegistroNotifier, AsyncValue<void>>(
  (ref) => NuevoRegistroNotifier(),
);

class NuevoRegistroNotifier extends StateNotifier<AsyncValue<void>> {
  NuevoRegistroNotifier() : super(const AsyncValue.data(null));

  Future<void> guardar(SessionModel session, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(sessionListProvider.notifier).addSession(session);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// --------------- Helper types for dynamic list ---------------

class _GymCardData {
  final TextEditingController name = TextEditingController();
  final TextEditingController series = TextEditingController();
  final TextEditingController reps = TextEditingController();
  final TextEditingController weight = TextEditingController();
  final TextEditingController rir = TextEditingController();
  final TextEditingController rest = TextEditingController(text: '60');

  GymExerciseModel toModel(int index) {
    return GymExerciseModel(
      orden: index + 1,
      nombreEjercicio: name.text.trim(),
      series: int.tryParse(series.text) ?? 0,
      repeticiones: int.tryParse(reps.text) ?? 0,
      pesoKg: double.tryParse(weight.text) ?? 0.0,
      rir: int.tryParse(rir.text) ?? 0,
      descansoSegundos: int.tryParse(rest.text) ?? 60,
    );
  }

  void dispose() {
    name.dispose();
    series.dispose();
    reps.dispose();
    weight.dispose();
    rir.dispose();
    rest.dispose();
  }
}

class _TechCardData {
  final TextEditingController name = TextEditingController();
  final TextEditingController series = TextEditingController();
  final TextEditingController reps = TextEditingController();
  final TextEditingController metric = TextEditingController();
  final TextEditingController rest = TextEditingController(text: '60');

  TechExerciseModel toModel(int index) {
    return TechExerciseModel(
      orden: index + 1,
      nombreEjercicio: name.text.trim(),
      series: int.tryParse(series.text) ?? 1,
      repeticiones: int.tryParse(reps.text) ?? 0,
      metricaPrincipal: double.tryParse(metric.text) ?? 0.0,
      descansoSegundos: int.tryParse(rest.text) ?? 60,
    );
  }

  void dispose() {
    name.dispose();
    series.dispose();
    reps.dispose();
    metric.dispose();
    rest.dispose();
  }
}

// --------------- Main Screen ---------------

class NuevoRegistroScreen extends ConsumerStatefulWidget {
  final SessionModel? editingSession;

  const NuevoRegistroScreen({super.key, this.editingSession});

  @override
  ConsumerState<NuevoRegistroScreen> createState() =>
      _NuevoRegistroScreenState();
}

class _NuevoRegistroScreenState extends ConsumerState<NuevoRegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Sección 1 – Metadata
  String _tipoSesion = 'Gimnasio';
  String _jornada = 'Matutina';
  DateTime _fecha = DateTime.now();
  final _faseCtrl = TextEditingController();
  final _suenoCtrl = TextEditingController(text: '8');
  final _limitantesCtrl = TextEditingController();
  double _fatiga = 3;
  double _intensidad = 5;

  // Sección 2 – Exercise lists
  final List<_GymCardData> _gymCards = [];
  final List<_TechCardData> _techCards = [];

  @override
  void initState() {
    super.initState();
    if (widget.editingSession != null) {
      _loadSessionData(widget.editingSession!);
    }
  }

  @override
  void dispose() {
    _faseCtrl.dispose();
    _suenoCtrl.dispose();
    _limitantesCtrl.dispose();
    for (final c in _gymCards) {
      c.dispose();
    }
    for (final c in _techCards) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadSessionData(SessionModel session) {
    _tipoSesion = session.tipoSesion;
    _jornada = session.jornada;
    _fecha = session.fecha;
    _faseCtrl.text = session.faseEntrenamiento;
    _suenoCtrl.text = session.horasSueno.toString();
    _limitantesCtrl.text = session.limitantes;
    _fatiga = session.fatiguaPreentrenamiento.toDouble();
    _intensidad = session.intensidadPercibida.toDouble();

    // Cargar ejercicios
    for (final ej in session.ejerciciosGim) {
      final card = _GymCardData();
      card.name.text = ej.nombreEjercicio;
      card.series.text = ej.series.toString();
      card.reps.text = ej.repeticiones.toString();
      card.weight.text = ej.pesoKg.toString();
      card.rir.text = ej.rir.toString();
      card.rest.text = ej.descansoSegundos.toString();
      _gymCards.add(card);
    }

    for (final ej in session.ejerciciosTech) {
      final card = _TechCardData();
      card.name.text = ej.nombreEjercicio;
      card.series.text = ej.series.toString();
      card.reps.text = ej.repeticiones.toString();
      card.metric.text = ej.metricaPrincipal.toString();
      card.rest.text = ej.descansoSegundos.toString();
      _techCards.add(card);
    }
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final savingState = ref.watch(nuevoRegistroProvider);
    final isSaving = savingState.isLoading;
    final isEditing = widget.editingSession != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Sesión' : 'Nueva Sesión'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const _SectionHeader(
                icon: Icons.info_outline, title: 'Contexto de la Sesión'),
            _buildMetadataCard(),
            const SizedBox(height: 20),
            const _SectionHeader(icon: Icons.list_alt, title: 'Ejercicios'),
            _buildExerciseList(),
            _buildAddExerciseButton(),
            const SizedBox(height: 28),
            _buildSaveButton(isSaving),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Section 1: Metadata ─────────────────────────────────

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de sesión
            InputDecorator(
              decoration: _decor('Tipo de Sesión', Icons.category_outlined),
              child: DropdownButton<String>(
                value: _tipoSesion,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Gimnasio', child: Text('🏋️ Gimnasio')),
                  DropdownMenuItem(value: 'Técnica', child: Text('🏃 Técnica')),
                ],
                onChanged: (v) {
                  setState(() {
                    _tipoSesion = v!;
                    // Clear exercises of opposite type when switching
                    if (_tipoSesion == 'Gimnasio') {
                      for (final c in _techCards) {
                        c.dispose();
                      }
                      _techCards.clear();
                    } else {
                      for (final c in _gymCards) {
                        c.dispose();
                      }
                      _gymCards.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            // Jornada
            InputDecorator(
              decoration: _decor('Jornada', Icons.schedule_outlined),
              child: DropdownButton<String>(
                value: _jornada,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Matutina', child: Text('🌅 Matutina')),
                  DropdownMenuItem(
                      value: 'Vespertina', child: Text('🌇 Vespertina')),
                ],
                onChanged: (v) {
                  setState(() {
                    _jornada = v!;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            // Fecha
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _fecha = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: _decor('Fecha', Icons.calendar_today_outlined),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_fecha),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Fase de entrenamiento
            TextFormField(
              controller: _faseCtrl,
              decoration: _decor('Fase de Entrenamiento (ej. Acumulación)',
                  Icons.layers_outlined),
            ),
            const SizedBox(height: 14),
            // Horas de sueño
            TextFormField(
              controller: _suenoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _decor('Horas de Sueño', Icons.bedtime_outlined),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 18),
            // Fatiga pre-entreno slider
            _buildSlider(
              label: 'Fatiga Pre-entreno',
              value: _fatiga,
              min: 1,
              max: 5,
              divisions: 4,
              colorSchemeColor: Theme.of(context).colorScheme.error,
              onChanged: (v) => setState(() => _fatiga = v),
            ),
            const SizedBox(height: 8),
            // RPE slider
            _buildSlider(
              label: 'Intensidad Percibida (RPE)',
              value: _intensidad,
              min: 1,
              max: 10,
              divisions: 9,
              colorSchemeColor: Theme.of(context).colorScheme.secondary,
              onChanged: (v) => setState(() => _intensidad = v),
            ),
            const SizedBox(height: 14),
            // Limitantes
            TextFormField(
              controller: _limitantesCtrl,
              maxLines: 3,
              decoration: _decor(
                'Limitantes / Observaciones',
                Icons.notes_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color colorSchemeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorSchemeColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorSchemeColor, thumbColor: colorSchemeColor),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─── Section 2: Exercise list ────────────────────────────

  Widget _buildExerciseList() {
    if (_tipoSesion == 'Gimnasio') {
      return Column(
        children: List.generate(_gymCards.length, (i) {
          final data = _gymCards[i];
          return GymExerciseCard(
            key: ValueKey(data),
            index: i,
            nameCtrl: data.name,
            seriesCtrl: data.series,
            repsCtrl: data.reps,
            weightCtrl: data.weight,
            rirCtrl: data.rir,
            restCtrl: data.rest,
            onRemove: () => setState(() {
              data.dispose();
              _gymCards.removeAt(i);
            }),
          );
        }),
      );
    } else {
      return Column(
        children: List.generate(_techCards.length, (i) {
          final data = _techCards[i];
          return TechExerciseCard(
            key: ValueKey(data),
            index: i,
            nameCtrl: data.name,
            seriesCtrl: data.series,
            repsCtrl: data.reps,
            metricCtrl: data.metric,
            restCtrl: data.rest,
            onRemove: () => setState(() {
              data.dispose();
              _techCards.removeAt(i);
            }),
          );
        }),
      );
    }
  }

  Widget _buildAddExerciseButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() {
        if (_tipoSesion == 'Gimnasio') {
          _gymCards.add(_GymCardData());
        } else {
          _techCards.add(_TechCardData());
        }
      }),
      icon: const Icon(Icons.add_circle_outline),
      label: Text('+ Agregar Ejercicio ($_tipoSesion)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Section 3: Save button ──────────────────────────────

  Widget _buildSaveButton(bool isSaving) {
    final isEditing = widget.editingSession != null;
    return FilledButton.icon(
      onPressed: isSaving ? null : _handleSave,
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_outlined),
      label: Text(isSaving
          ? 'Guardando...'
          : (isEditing ? 'ACTUALIZAR SESIÓN' : 'GUARDAR SESIÓN')),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─── Save logic ──────────────────────────────────────────

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Cerrar teclado antes de guardar para evitar glitches visuales
    FocusScope.of(context).unfocus();

    // Validar que haya al menos un ejercicio
    if (_gymCards.isEmpty && _techCards.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Debes agregar al menos un ejercicio'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final user = ref.read(authStateProvider).value;
    final userId = user?.uid ?? 'single_user';
    final isEditing = widget.editingSession != null;

    final session = SessionModel(
      idSesion: isEditing ? widget.editingSession!.idSesion : const Uuid().v4(),
      userId: userId,
      idAtleta: userId,
      fecha: _fecha,
      tipoSesion: _tipoSesion,
      faseEntrenamiento: _faseCtrl.text.trim(),
      horasSueno: double.tryParse(_suenoCtrl.text) ?? 8.0,
      fatiguaPreentrenamiento: _fatiga.toInt(),
      intensidadPercibida: _intensidad.toInt(),
      limitantes: _limitantesCtrl.text.trim(),
      jornada: _jornada,
      ejerciciosGim: List.generate(
        _gymCards.length,
        (i) => _gymCards[i].toModel(i),
      ),
      ejerciciosTech: List.generate(
        _techCards.length,
        (i) => _techCards[i].toModel(i),
      ),
      isSynced: false,
      editadoEn: isEditing ? DateTime.now() : null,
    );

    // Guardar el ScaffoldMessengerState antes de la operación asincrónica
    // Guardar referencias antes de la operación asincrónica para evitar errores de contexto
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isEditing) {
      // Actualizar sesión existente
      await ref.read(sessionListProvider.notifier).updateSession(session);
    } else {
      // Crear nueva sesión
      await ref.read(nuevoRegistroProvider.notifier).guardar(session, ref);
    }

    if (!mounted) return;

    final error = ref.read(nuevoRegistroProvider).error;

    if (error != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Error al guardar: $error'),
            backgroundColor: Colors.red),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? '✅ Sesión actualizada correctamente'
              : '✅ Sesión guardada correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (isEditing) {
        navigator
            .pop(); // Solo cerramos si estamos en modo edición (pushed route)
      } else {
        // Si es un registro nuevo, podrías limpiar el formulario o simplemente dejarlo así.
        // Por ahora, lo dejamos así para que el usuario vea el éxito.
        _limpiarFormulario();
      }
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _faseCtrl.clear();
      _gymCards.clear();
      _techCards.clear();
      _fatiga = 3;
      _intensidad = 5;
    });
  }

  // ─── Util ────────────────────────────────────────────────

  InputDecoration _decor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }
}

// ─── Reusable section header ─────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
