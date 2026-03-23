import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/profile_screen.dart';

class AthleteDrawer extends ConsumerWidget {
  const AthleteDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // Cabecera: ID Card deportiva
          _buildHeader(context, ref),
          
          // Cuerpo: Lista de opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Mi Perfil
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text('Mi Perfil'),
                  subtitle: const Text('Editar información personal'),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                // Sincronización
                Consumer(
                  builder: (context, ref, child) {
                    final sessions = ref.watch(sessionListProvider);
                    final unsyncedCount = sessions.where((s) => !s.isSynced).length;
                    
                    return ListTile(
                      leading: const Icon(Icons.cloud, color: Colors.orange),
                      title: const Text('Sincronización'),
                      subtitle: Text(
                        unsyncedCount > 0
                            ? '$unsyncedCount pendiente(s)'
                            : 'Todo sincronizado',
                        style: TextStyle(
                          color: unsyncedCount > 0 ? Colors.orange : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showSyncDialog(context, ref);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Pie: Cerrar Sesión
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white54,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Usuario no disponible',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar con iniciales
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      profile.nombreCompleto.isNotEmpty
                          ? profile.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nombre y Rol en la misma línea
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.nombreCompleto.isNotEmpty
                              ? profile.nombreCompleto
                              : 'Sin nombre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: profile.rol == 'entrenador'
                                ? Colors.amber.shade700
                                : Colors.green.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            profile.rol == 'entrenador' ? 'Entrenador' : 'Atleta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Línea decorativa tipo "ID Card"
              const SizedBox(height: 8),
              const Divider(color: Colors.white30, thickness: 1),
              const SizedBox(height: 4),
              
              // Información adicional compacta
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _buildInfoChip(
                      Icons.sports,
                      profile.perfilDeportivo.isNotEmpty
                          ? profile.perfilDeportivo
                          : 'Sin perfil',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _buildInfoChip(
                      Icons.category,
                      profile.categoria.isNotEmpty ? profile.categoria : 'Sin categoría',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, __) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white70, size: 40),
            SizedBox(height: 10),
            Text(
              'Error cargando perfil',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSyncDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado de sincronización:'),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final sessions = ref.watch(sessionListProvider);
                final unsyncedCount = sessions.where((s) => !s.isSynced).length;
                
                return Text(
                  '$unsyncedCount sesión(es) pendiente(s) de subir',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Acciones disponibles:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Forzar Sincronización'),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(sessionListProvider.notifier).syncPending();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sincronización completada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
