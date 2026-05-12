import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/app_theme.dart';
import '../screens/profile_screen.dart';
import '../screens/axon_vbt_screen.dart';
import '../screens/axon_peak_screen.dart';

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
                Consumer(
                  builder: (context, ref, child) {
                    final theme = Theme.of(context);
                    return ListTile(
                      leading: Icon(Icons.person, color: theme.colorScheme.onSurface),
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
                    );
                  },
                ),


                // Axon VBT
                ListTile(
                  leading: Icon(Icons.biotech_rounded,
                      color: Theme.of(context).colorScheme.onSurface),
                  title: const Text('Axon VBT'),
                  subtitle: const Text('VBT · RSI · Análisis en tiempo real'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AxonVBTScreen(),
                      ),
                    );
                  },
                ),


                // Axon Peak
                ListTile(
                  leading: Icon(Icons.terrain_rounded,
                      color: Theme.of(context).colorScheme.onSurface),
                  title: const Text('Axon Peak'),
                  subtitle: const Text('Periodización y Efecto Dominó'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AxonPeakScreen(),
                      ),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),

                // Sincronización
                Consumer(
                  builder: (context, ref, child) {
                    final sessions = ref.watch(sessionListProvider);
                    final unsyncedCount =
                        sessions.where((s) => !s.isSynced).length;
                    final theme = Theme.of(context);

                    return ListTile(
                      leading: Icon(Icons.cloud, color: theme.colorScheme.onSurface),
                      title: const Text('Sincronización'),
                      subtitle: Text(
                        unsyncedCount > 0
                            ? '$unsyncedCount pendiente(s)'
                            : 'Todo sincronizado',
                        style: TextStyle(
                          color: unsyncedCount > 0
                              ? AppTheme.accentAmber
                              : Colors.green,
                        ),
                      ),
                      onTap: () {
                        // No cerrar drawer aquí para mantener el contexto vivo
                        _showSyncDialog(context, ref);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Tema: Cambio entre claro/oscuro
          Consumer(
            builder: (context, ref, child) {
              final currentThemeMode = ref.watch(themeProvider);
              IconData themeIcon;
              String themeText;
              String themeSubtitle;

              switch (currentThemeMode) {
                case ThemeMode.light:
                  themeIcon = Icons.light_mode;
                  themeText = 'Tema Claro';
                  themeSubtitle = 'Modo claro activado';
                  break;
                case ThemeMode.dark:
                  themeIcon = Icons.dark_mode;
                  themeText = 'Tema Oscuro';
                  themeSubtitle = 'Modo oscuro activado';
                  break;
                case ThemeMode.system:
                  themeIcon = Icons.phone_iphone;
                  themeText = 'Tema Automático';
                  themeSubtitle = 'Sigue configuración del sistema';
                  break;
              }

              return ListTile(
                leading: Icon(themeIcon, color: Theme.of(context).colorScheme.onSurface),
                title: Text(themeText),
                subtitle: Text(themeSubtitle),
                onTap: () {
                  ThemeMode newMode;
                  switch (currentThemeMode) {
                    case ThemeMode.light:
                      newMode = ThemeMode.dark;
                      break;
                    case ThemeMode.dark:
                      newMode = ThemeMode.system;
                      break;
                    case ThemeMode.system:
                      newMode = ThemeMode.light;
                      break;
                  }
                  ref.read(themeProvider.notifier).setThemeMode(newMode);
                },
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(),
          ),

          // Pie: Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            subtitle: const Text('Salir de la cuenta actual'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.8),
            theme.primaryColor.withValues(alpha: 0.6),
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
                            profile.rol == 'entrenador'
                                ? 'Entrenador'
                                : 'Atleta',
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
                      profile.categoriaCalculada,
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Forzar Sincronización'),
            onPressed: () async {
              Navigator.pop(dialogContext); // Cierra solo el diálogo
              await ref.read(sessionListProvider.notifier).syncPending();

              // Usamos el context del Drawer (que sigue abierto)
              if (context.mounted) {
                Navigator.pop(context); // Ahora cerramos el drawer
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
