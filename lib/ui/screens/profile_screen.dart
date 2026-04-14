import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../data/models/user_profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No hay perfil disponible'),
            );
          }
          return ListView(
            children: [
              _buildEditableField(
                context,
                'Nombre Completo',
                profile.nombreCompleto,
                () => _editField(
                    context, 'nombreCompleto', profile.nombreCompleto, profile),
              ),
              _buildEditableField(
                context,
                'Fecha de Nacimiento',
                _formatDate(profile.fechaNacimiento),
                () => _editDateField(context, 'fechaNacimiento',
                    profile.fechaNacimiento, profile),
                isDate: true,
              ),
              _buildEditableField(
                context,
                'Sexo',
                profile.sexo,
                () => _editSexoField(context, profile),
              ),
              _buildEditableField(
                context,
                'Disciplina/Prueba',
                profile.perfilDeportivo,
                () => _editPerfilDeportivoField(context, profile),
              ),
              _buildEditableField(
                context,
                'Mejor Marca',
                profile.mejorMarca,
                () => _editField(
                    context, 'mejorMarca', profile.mejorMarca, profile),
              ),
              _buildEditableField(
                context,
                'Fecha de Mejor Marca',
                _formatDate(profile.fechaMejorMarca),
                () => _editDateField(context, 'fechaMejorMarca',
                    profile.fechaMejorMarca, profile),
                isDate: true,
              ),
              _buildEditableField(
                context,
                'Competencia Objetivo',
                profile.competenciaObjetivo,
                () => _editField(context, 'competenciaObjetivo',
                    profile.competenciaObjetivo, profile),
              ),
              ListTile(
                title: Text(
                  'Categoría (Auto)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(profile.categoriaCalculada),
                trailing: Icon(Icons.calculate,
                    size: 20, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap, {
    bool isDate = false,
  }) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(value.isEmpty ? 'No definido' : value),
      trailing: Icon(Icons.edit,
          size: 20, color: Theme.of(context).colorScheme.primary),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _editField(
    BuildContext context,
    String fieldName,
    String currentValue,
    UserProfileModel profile,
  ) async {
    final controller =
        TextEditingController(text: currentValue.isEmpty ? '' : currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${_getFieldLabel(fieldName)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ingresa el nuevo valor',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      await _updateProfileField(fieldName, result, profile);
    }
  }

  Future<void> _editDateField(
    BuildContext context,
    String fieldName,
    DateTime currentValue,
    UserProfileModel profile,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      await _updateProfileField(fieldName, picked, profile);
    }
  }

  Future<void> _editSexoField(
    BuildContext context,
    UserProfileModel profile,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar Sexo'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Masculino'),
            child: const Text('Masculino'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Femenino'),
            child: const Text('Femenino'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Otro'),
            child: const Text('Otro'),
          ),
        ],
      ),
    );

    if (selected != null && selected != profile.sexo) {
      await _updateProfileField('sexo', selected, profile);
    }
  }

  Future<void> _editPerfilDeportivoField(
    BuildContext context,
    UserProfileModel profile,
  ) async {
    final controller = TextEditingController(
        text: profile.perfilDeportivo.isEmpty ? '' : profile.perfilDeportivo);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Disciplina/Prueba'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu disciplina o prueba',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result != profile.perfilDeportivo) {
      await _updateProfileField('perfilDeportivo', result, profile);
    }
  }

  Future<void> _updateProfileField(
    String fieldName,
    dynamic value,
    UserProfileModel profile,
  ) async {
    final notifier = ref.read(userProfileProvider.notifier);
    final currentProfile = ref.read(userProfileProvider).value;

    if (currentProfile == null) return;

    UserProfileModel updatedProfile;
    switch (fieldName) {
      case 'nombreCompleto':
        updatedProfile = currentProfile.copyWith(
          nombreCompleto: value,
        );
        break;
      case 'fechaNacimiento':
        updatedProfile = currentProfile.copyWith(
          fechaNacimiento: value,
        );
        break;
      case 'sexo':
        updatedProfile = currentProfile.copyWith(sexo: value);
        break;
      case 'perfilDeportivo':
        updatedProfile = currentProfile.copyWith(perfilDeportivo: value);
        break;
      case 'mejorMarca':
        updatedProfile = currentProfile.copyWith(mejorMarca: value);
        break;
      case 'fechaMejorMarca':
        updatedProfile = currentProfile.copyWith(
          fechaMejorMarca: value,
        );
        break;
      case 'competenciaObjetivo':
        updatedProfile = currentProfile.copyWith(competenciaObjetivo: value);
        break;
      case 'categoria':
        updatedProfile = currentProfile.copyWith(categoria: value);
        break;
      default:
        return;
    }

    await notifier.saveAndSyncProfile(updatedProfile);
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'nombreCompleto':
        return 'Nombre Completo';
      case 'fechaNacimiento':
        return 'Fecha de Nacimiento';
      case 'sexo':
        return 'Sexo';
      case 'perfilDeportivo':
        return 'Disciplina/Prueba';
      case 'mejorMarca':
        return 'Mejor Marca';
      case 'fechaMejorMarca':
        return 'Fecha de Mejor Marca';
      case 'competenciaObjetivo':
        return 'Competencia Objetivo';
      case 'categoria':
        return 'Categoría';
      default:
        return fieldName;
    }
  }
}
