import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/auth_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCompletoController = TextEditingController();
  final _mejorMarcaController = TextEditingController();
  final _competenciaController = TextEditingController();
  final _perfilController = TextEditingController();
  final _coachIdController = TextEditingController();

  DateTime _fechaNacimiento =
      DateTime.now().subtract(const Duration(days: 365 * 20));
  DateTime _fechaMejorMarca = DateTime.now();
  String _sexo = 'Masculino';
  String _rol = 'atleta';

  final List<String> _sexoOptions = ['Masculino', 'Femenino', 'Otro'];
  final List<String> _rolOptions = ['atleta', 'entrenador'];

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _mejorMarcaController.dispose();
    _competenciaController.dispose();
    _perfilController.dispose();
    _coachIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isNacimiento) async {
    final initialDate = isNacimiento ? _fechaNacimiento : _fechaMejorMarca;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isNacimiento) {
          _fechaNacimiento = picked;
        } else {
          _fechaMejorMarca = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final profile = UserProfileModel(
      uid: user.uid,
      nombreCompleto: _nombreCompletoController.text,
      fechaNacimiento: _fechaNacimiento,
      sexo: _sexo,
      perfilDeportivo: _perfilController.text,
      mejorMarca: _mejorMarcaController.text,
      fechaMejorMarca: _fechaMejorMarca,
      competenciaObjetivo: _competenciaController.text,
      categoria: UserProfileModel.calcularCategoria(_fechaNacimiento),
      rol: _rol,
      coachId: _rol == 'atleta' ? _coachIdController.text : '',
    );

    await ref.read(userProfileProvider.notifier).saveAndSyncProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombreCompletoController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _rol,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: _rolOptions
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setState(() => _rol = val!),
                  ),
                  const SizedBox(height: 16),
                  if (_rol == 'atleta') ...[
                    TextFormField(
                      controller: _coachIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID del Entrenador (Opcional)',
                        prefixIcon: Icon(Icons.sports),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildDateSelector(
                    'Fecha de Nacimiento',
                    _fechaNacimiento,
                    () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _sexo,
                    decoration: const InputDecoration(
                      labelText: 'Sexo',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: _sexoOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _sexo = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _perfilController,
                    decoration: const InputDecoration(
                      labelText: 'Perfil (Ej: Saltos, Velocidad)',
                      prefixIcon: Icon(Icons.directions_run),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mejorMarcaController,
                    decoration: const InputDecoration(
                      labelText: 'Mejor Marca (e.g. 500kg Total)',
                      prefixIcon: Icon(Icons.emoji_events_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateSelector(
                    'Fecha de Mejor Marca',
                    _fechaMejorMarca,
                    () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _competenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Competencia Objetivo',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _submitForm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'GUARDAR PERFIL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${date.toLocal()}'.split(' ')[0],
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
