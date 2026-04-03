import 'package:flutter/material.dart';
import 'vbt_calibration_screen.dart';
import 'plyometry_analysis_screen.dart';

/// Pantalla principal del Laboratorio Axon.
/// Muestra dos grandes tarjetas para navegar a los módulos VBT y Pliometría.
class LaboratorioAxonScreen extends StatelessWidget {
  const LaboratorioAxonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Laboratorio Axon'),
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con icono
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.biotech_rounded,
                            color: Color(0xFF0284C7),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Análisis de Rendimiento',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Selecciona el tipo de análisis',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Cards de módulos
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _LabCategoryCard(
                    icon: Icons.fitness_center_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFBAE6FD),
                    title: 'Potencia y Gimnasio',
                    subtitle: 'VBT — Velocity Based Training',
                    description:
                        'Analiza videos de sentadilla, arranque, press y más. '
                        'Calibración automática por diámetro del disco.',
                    tags: const ['Sentadilla', 'Arranque', 'Press Banca'],
                    accentColor: const Color(0xFF0284C7),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VbtCalibrationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabCategoryCard(
                    icon: Icons.directions_run_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    title: 'Pliometría y Carrera',
                    subtitle: 'RSI — Reactive Strength Index',
                    description:
                        'Calcula el Índice de Fuerza Reactiva (RSI) a partir de tus videos '
                        'de salto. Detección automática de vuelo mediante IA.',
                    tags: const ['CMJ', 'Bounds', 'Sprints'],
                    accentColor: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlyometryAnalysisScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info banner
                  _InfoBanner(cs: cs),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de Categoría ─────────────────────────────────────────────────────

class _LabCategoryCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String description;
  final List<String> tags;
  final Color accentColor;
  final VoidCallback onTap;

  const _LabCategoryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_LabCategoryCard> createState() => _LabCategoryCardState();
}

class _LabCategoryCardState extends State<_LabCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          Icon(widget.icon, color: widget.iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.accentColor.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.accentColor
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner informativo ────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final ColorScheme cs;
  const _InfoBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_rounded,
              color: Color(0xFF0284C7), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Los datos se guardan automáticamente y se integran con tu ADN del Atleta en el perfil.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
