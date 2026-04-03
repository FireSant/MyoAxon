import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/axon_analysis_model.dart';
import 'auth_provider.dart';

// ── Hive Box Provider ────────────────────────────────────────────────────────

final axonAnalysisBoxProvider = Provider<Box<AxonAnalysisModel>>((ref) {
  return Hive.box<AxonAnalysisModel>('axon_analysis_box');
});

// ── Lista de Análisis ────────────────────────────────────────────────────────

class AxonLabNotifier extends StateNotifier<List<AxonAnalysisModel>> {
  final Box<AxonAnalysisModel> _box;
  final Ref _ref;

  AxonLabNotifier(this._box, this._ref) : super([]) {
    _load();
  }

  void _load() {
    final items = _box.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = items;
  }

  /// Guarda un resultado de análisis localmente y actualiza Firestore.
  Future<void> saveResult(AxonAnalysisModel result) async {
    try {
      await _box.put(result.id, result);
      _load();

      // Intentar sincronizar con Firestore
      try {
        await FirebaseFirestore.instance
            .collection('axon_analyses')
            .doc(result.id)
            .set(result.toFirebase());

        // Marcar como sincronizado
        final synced = result.copyWith(isSynced: true);
        await _box.put(synced.id, synced);
        _load();

        // Actualizar ADN del atleta en Firestore
        await _updateAthleteDna(result);
      } catch (e) {
        debugPrint('⚠️ Firestore sync failed: $e');
        // Sin conexión → quedará pendiente, no es un crash fatal
      }
    } catch (e, stack) {
      debugPrint('❌ FATAL SAVE ERROR: $e');
      debugPrint('StackTrace: $stack');
      rethrow; // Rethrow to allow UI to catch it if they have a listener
    }
  }

  /// Actualiza el "ADN del Atleta" con la última métrica del análisis.
  Future<void> _updateAthleteDna(AxonAnalysisModel result) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final Map<String, dynamic> dnaUpdate = {
      'ultima_actualizacion': DateTime.now().toIso8601String(),
    };

    if (result.isVbt) {
      dnaUpdate['vbt_ultima_vmc'] = result.vmcMs;
      dnaUpdate['vbt_ejercicio'] = result.exerciseLabel;
    } else if (result.isPlyometry) {
      dnaUpdate['ply_ultimo_rsi'] = result.rsi;
      dnaUpdate['ply_ejercicio'] = result.exerciseLabel;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dna_atletico')
        .doc('axon_lab')
        .set(dnaUpdate, SetOptions(merge: true));
  }

  /// Retorna análisis filtrados por tipo ('vbt' o 'plyometry').
  List<AxonAnalysisModel> byType(String tipo) {
    return state.where((a) => a.tipo == tipo).toList();
  }

  /// Retorna análisis agrupados por carpeta.
  Map<String, List<AxonAnalysisModel>> byFolder() {
    final Map<String, List<AxonAnalysisModel>> grouped = {};
    for (final a in state) {
      grouped.putIfAbsent(a.folderName, () => []).add(a);
    }
    return grouped;
  }

  /// Elimina un análisis local.
  Future<void> deleteResult(String id) async {
    await _box.delete(id);
    _load();
  }
}

final axonLabProvider =
    StateNotifierProvider<AxonLabNotifier, List<AxonAnalysisModel>>((ref) {
  final box = ref.watch(axonAnalysisBoxProvider);
  return AxonLabNotifier(box, ref);
});
