import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/axon_peak_provider.dart';
import '../../data/models/axon_peak_config_model.dart';
import '../../data/models/training_block_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/session_model.dart';

class AxonPeakScreen extends ConsumerStatefulWidget {
  final UserProfileModel? athleteProfile;
  const AxonPeakScreen({super.key, this.athleteProfile});

  @override
  ConsumerState<AxonPeakScreen> createState() => _AxonPeakScreenState();
}

class _AxonPeakScreenState extends ConsumerState<AxonPeakScreen> {
  // Config state
  DateTime _targetDate =
      DateTime.now().add(const Duration(days: 84)); // 12 weeks
  int _weeksPerBlock = 4;
  final bool _isTaperActive = true;
  String _periodizationMethod = 'StepLoading';

  final Map<String, double> _exerciseIncrements =
      {}; // Now it's % increment (e.g. 2.5%)
  final Map<String, double> _initialLoads = {};
  final Map<String, int> _initialReps = {};

  // Search controller for hybrid exercise search
  final TextEditingController _exerciseSearchController =
      TextEditingController();

  List<String> _getAvailableExercises() {
    try {
      final box = Hive.box<SessionModel>('sessions_box');
      final Set<String> exercises = {};
      for (var session in box.values) {
        for (var ex in session.ejerciciosGim) {
          if (ex.nombreEjercicio.isNotEmpty) {
            exercises.add(ex.nombreEjercicio);
          }
        }
      }
      return exercises.toList()..sort();
    } catch (e) {
      return ['Sentadilla', 'Press Banca', 'Peso Muerto', 'Clean'];
    }
  }

  void _addExercise(String name) {
    if (name.isEmpty || _exerciseIncrements.containsKey(name)) return;
    setState(() {
      _exerciseIncrements[name] = 2.5; // Default increment %
      _initialLoads[name] = 100.0; // Default starting load
      _initialReps[name] = 5; // Default reps
    });
    _exerciseSearchController.clear();
  }

  @override
  void dispose() {
    _exerciseSearchController.dispose();
    super.dispose();
  }

  // Getter accesible en todos los métodos del State
  bool get isCoachViewing => widget.athleteProfile != null;

  @override
  Widget build(BuildContext context) {
    final configState = isCoachViewing
        ? ref.watch(axonPeakConfigByAthleteProvider(widget.athleteProfile!.uid))
        : ref.watch(axonPeakConfigProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
            isCoachViewing
                ? 'Axon Peak: ${widget.athleteProfile!.nombreCompleto}'
                : 'Axon Peak PRO',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showScienceInfoDialog,
          )
        ],
      ),
      body: configState.when(
        data: (config) {
          if (config == null) {
            if (isCoachViewing) {
              return const Center(
                child: Text('El atleta aún no ha configurado su Axon Peak.'),
              );
            }
            return _buildSetupWizard(context);
          }
          return Column(
            children: [
              if (isCoachViewing)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'MODO LECTURA: VIENDO COMO ENTRENADOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(child: _buildActiveMacrocycle(context, config)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showScienceInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Color(0xFF6D28D9)),
            SizedBox(width: 8),
            Text('Base Científica (VBT)', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Parámetros Científicos (González-Badillo, 2011)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Ajuste (S1): 70%-75% | >0.65 m/s | RIR 3-4'),
              Text('Carga (S2): 80% | 0.50-0.60 m/s | RIR 2'),
              Text('Pico (S3): 85%-90% | 0.35-0.45 m/s | RIR 0-1'),
              Text('Descarga (S4): 60% | >0.80 m/s | RIR 5+'),
              SizedBox(height: 20),
              Text('Métodos de Periodización',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                  '• Por Pasos: Superación de récords relativos en cada bloque. Recomendable para etapas generales y atletas Principiantes/Intermedios.'),
              Text(
                  '• Lineal Tradicional: Intensidad ascendente a lo largo de todo el macrociclo, manteniendo el 1RM base. Recomendado para Avanzados.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido')),
        ],
      ),
    );
  }

  Widget _buildSetupWizard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generador Científico de Periodización',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 20),

          // 1. Perfil y Método
          _buildGlassCard(
            title: '1. Método de Carga',
            icon: Icons.settings_suggest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _periodizationMethod,
                  decoration: InputDecoration(
                      labelText: 'Método de Periodización',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.info, color: Colors.grey),
                        onPressed: _showScienceInfoDialog,
                      )),
                  items: const [
                    DropdownMenuItem(
                        value: 'StepLoading', child: Text('Carga por Pasos')),
                    DropdownMenuItem(
                        value: 'Linear', child: Text('Lineal Tradicional')),
                  ],
                  onChanged: (val) =>
                      setState(() => _periodizationMethod = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Horizonte Temporal
          _buildGlassCard(
            title: '2. Horizonte Temporal',
            icon: Icons.calendar_today,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Fecha Meta'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_targetDate)),
                  trailing:
                      const Icon(Icons.edit_calendar, color: Color(0xFF8B5CF6)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _targetDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setState(() => _targetDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Semanas por Bloque'),
                  subtitle: Text(
                      '$_weeksPerBlock semanas (Estructura ${_weeksPerBlock - 1}:1)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _weeksPerBlock > 2
                            ? () => setState(() => _weeksPerBlock--)
                            : null,
                      ),
                      Text('$_weeksPerBlock',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _weeksPerBlock < 6
                            ? () => setState(() => _weeksPerBlock++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Selección de Ejercicios y 1RM
          _buildGlassCard(
            title: '3. Test de RM (Semilla)',
            icon: Icons.fitness_center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final available = _getAvailableExercises();
                    if (textEditingValue.text.isEmpty) {
                      return available;
                    }
                    return available.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _addExercise(selection);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Buscar o agregar ejercicio nuevo',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF8B5CF6)),
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              _addExercise(controller.text);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (val) {
                        if (val.isNotEmpty) _addExercise(val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_exerciseIncrements.isEmpty)
                  const Text('Agrega ejercicios para estimar el 1RM.',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic)),
                ..._exerciseIncrements.keys.map((exercise) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(exercise,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _exerciseIncrements.remove(exercise);
                                    _initialLoads.remove(exercise);
                                    _initialReps.remove(exercise);
                                  });
                                },
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _initialLoads[exercise].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Peso (kg)', isDense: true),
                                  onChanged: (val) => _initialLoads[exercise] =
                                      double.tryParse(val) ?? 0.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _initialReps[exercise].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Reps', isDense: true),
                                  onChanged: (val) => _initialReps[exercise] =
                                      int.tryParse(val) ?? 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      _exerciseIncrements[exercise].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: '+Inc. %', isDense: true),
                                  onChanged: (val) =>
                                      _exerciseIncrements[exercise] =
                                          double.tryParse(val) ?? 0.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _periodizationMethod == 'Linear'
                                ? 'Guía de Incremento (Lineal):\n• Avanzados: 1 - 2.5%\n• Intermedios: 2.5 - 5%\n• Principiantes: > 5%'
                                : 'Guía de Incremento (Por Pasos):\n• Recomendado: 1 - 3% para evitar estancamiento',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Generar
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (_exerciseIncrements.isEmpty || isCoachViewing)
                  ? null
                  : () {
                      ref
                          .read(axonPeakConfigProvider.notifier)
                          .initializeMacrocycle(
                            targetDate: _targetDate,
                            weeksPerBlock: _weeksPerBlock,
                            isTaperActive: _isTaperActive,
                            periodizationMethod: _periodizationMethod,
                            initialLoads: _initialLoads,
                            initialReps: _initialReps,
                            exerciseIncrements: _exerciseIncrements,
                          );
                    },
              child: const Text('GENERAR MACROCICLO',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGlassCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMacrocycle(
      BuildContext context, AxonPeakConfigModel config) {
    final today = DateTime.now();
    final daysRemaining = config.targetDate.difference(today).inDays;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.science, color: Colors.white70, size: 16),
                    const SizedBox(width: 5),
                    Text('1RM BASE ACTIVO (${config.periodizationMethod})',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  alignment: WrapAlignment.center,
                  children: config.exercise1RM.entries
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${e.key}: ${e.value.toStringAsFixed(1)}kg',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  '$daysRemaining',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.w900),
                ),
                const Text('DÍAS PARA LA META',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isCoachViewing)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Reset',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Romper la cadena?'),
                              content: const Text(
                                  'Esto eliminará la progresión actual y el cálculo de 1RM global.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref
                                        .read(axonPeakConfigProvider.notifier)
                                        .resetProgression();
                                  },
                                  child: const Text('Aceptar',
                                      style: TextStyle(color: Colors.red)),
                                )
                              ],
                            ),
                          );
                        },
                      )
                  ],
                )
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final block = config.blocks[index];
                return _buildBlockCard(context, block, index, config);
              },
              childCount: config.blocks.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockCard(BuildContext context, TrainingBlockModel block,
      int blockIndex, AxonPeakConfigModel config) {
    final isCurrent = block.status == 'En curso';
    final isCompleted = block.status == 'Completado';

    Color statusColor = Colors.grey;
    if (isCurrent) statusColor = const Color(0xFF10B981); // Emerald
    if (isCompleted) statusColor = const Color(0xFF6D28D9); // Purple

    // Generar una key única basada en las cargas del bloque.
    // Cuando applyBlockDecisions modifica las cargas, esta key cambia,
    // forzando a Flutter a destruir y reconstruir los TextFormField
    // con los nuevos initialValue.
    final loadsHash = block.exerciseLoads.entries
        .map((e) => '${e.key}:${e.value.join(",")}')
        .join('|');

    return Container(
      key: ValueKey('block_${block.blockNumber}_$loadsHash'),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: statusColor, width: 2)
            : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bloque ${block.blockNumber}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    block.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),

          // Body (Table Dual View + VMC)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                        flex: 2,
                        child: Text('Ejercicio',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey))),
                    for (int i = 0; i < config.weeksPerBlock; i++)
                      Expanded(
                          child: Center(
                              child: Text('S${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)))),
                  ],
                ),
                const Divider(),
                ...block.exerciseLoads.entries.map((entry) {
                  final exercise = entry.key;
                  final loads = entry.value;
                  final percents = block.exercisePercentages[exercise] ?? [];
                  final vmcs = block.recordedVMC[exercise] ?? [];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(exercise,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            )),
                        for (int w = 0; w < loads.length; w++)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Column(
                                children: [
                                  Text('${percents[w].toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold)),
                                  TextFormField(
                                    enabled: !isCoachViewing,
                                    initialValue: loads[w].toStringAsFixed(1),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 4)),
                                    onFieldSubmitted: (val) {
                                      if (isCoachViewing) return;
                                      final normalizedVal =
                                          val.replaceAll(',', '.');
                                      final newLoad =
                                          double.tryParse(normalizedVal) ??
                                              loads[w];
                                      if (newLoad != loads[w]) {
                                        ref
                                            .read(
                                                axonPeakConfigProvider.notifier)
                                            .updateLoad(blockIndex, exercise, w,
                                                newLoad);
                                      }
                                    },
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      enabled: !isCoachViewing,
                                      initialValue:
                                          (vmcs.length > w && vmcs[w] > 0)
                                              ? vmcs[w].toStringAsFixed(2)
                                              : '',
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueAccent),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 4),
                                        hintText: 'm/s',
                                        hintStyle: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey
                                                .withValues(alpha: 0.5)),
                                        border: InputBorder.none,
                                        filled: true,
                                        fillColor: Colors.blueAccent
                                            .withValues(alpha: 0.05),
                                      ),
                                      onChanged: (val) {
                                        if (isCoachViewing) return;
                                        final normalizedVal =
                                            val.replaceAll(',', '.');
                                        final vmc =
                                            double.tryParse(normalizedVal);
                                        if (vmc != null) {
                                          ref
                                              .read(axonPeakConfigProvider
                                                  .notifier)
                                              .updateVMC(
                                                  blockIndex, exercise, w, vmc);
                                        }
                                      },
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Action Footer
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('FINALIZAR BLOQUE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      _showCompleteBlockDialog(context, blockIndex),
                ),
              ),
            )
        ],
      ),
    );
  }

  void _showCompleteBlockDialog(BuildContext context, int blockIndex) {
    // Pedir las recomendaciones del proveedor (ahora es síncrono y sin efectos secundarios)
    final recommendations = ref
        .read(axonPeakConfigProvider.notifier)
        .getRecommendations(blockIndex);

    // Mapa local para que el usuario pueda decidir qué ejercicios incrementan su 1RM global
    Map<String, bool> applyIncrements = {};
    for (var key in recommendations.keys) {
      // Por defecto true si la recomendación contiene 'confirmar el aumento'
      applyIncrements[key] =
          recommendations[key]!.contains('confirmar el aumento');
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Forzar decisión
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Cierre Científico de Bloque 🧬'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Análisis VBT y Recomendaciones:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...recommendations.entries.map((e) {
                      final exercise = e.key;
                      final suggestion = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(suggestion,
                                  style: const TextStyle(fontSize: 12)),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Aplicar incremento de 1RM',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Switch(
                                    value: applyIncrements[exercise] ?? false,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        applyIncrements[exercise] = val;
                                      });
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(axonPeakConfigProvider.notifier)
                      .applyBlockDecisions(blockIndex, applyIncrements);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Bloque finalizado con éxito. Decisiones aplicadas.'),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white),
                child: const Text('CERRAR BLOQUE Y AVANZAR'),
              )
            ],
          );
        });
      },
    );
  }
}
