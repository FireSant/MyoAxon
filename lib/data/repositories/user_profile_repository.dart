import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

class UserProfileRepository {
  static const String _boxName = 'user_profiles_box';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Box<UserProfileModel> get _box => Hive.box<UserProfileModel>(_boxName);

  // Guardar o actualizar perfil
  Future<void> saveProfile(UserProfileModel profile) async {
    await _box.put(profile.uid, profile);
  }

  // Obtener perfil por ID
  UserProfileModel? getProfile(String uid) {
    return _box.get(uid);
  }

  // Obtener perfil por código de vinculación (linkCode)
  Future<UserProfileModel?> getProfileByLinkCode(String linkCode) async {
    try {
      final all = _box.values.where((p) => p.linkCode == linkCode);
      if (all.isNotEmpty) return all.first;
    } catch (_) {}
    return null;
  }

  // Marcar como sincronizado
  Future<void> markSynced(String uid) async {
    final profile = _box.get(uid);
    if (profile != null) {
      profile.isSynced = true;
      await profile.save();
    }
  }

  // Limpiar perfil local del usuario específico (al cerrar sesión)
  Future<void> clearProfile({String? uid}) async {
    if (uid != null) {
      await _box.delete(uid);
    } else {
      await _box.clear();
    }
  }

  // Obtener de Firebase
  Future<UserProfileModel?> fetchProfileFromFirebase(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfileModel.fromFirebase(doc.data()!, uid);
        await saveProfile(profile);
        return profile;
      }
    } catch (e) {
      // Error fetching profile from Firebase
    }
    return null;
  }

  // Sincronizar a Firebase
  Future<void> syncProfileToFirebase(UserProfileModel profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirebase());
      await markSynced(profile.uid);
    } catch (e) {
      // Error syncing profile to Firebase
      rethrow;
    }
  }

  // Obtener atletas de un entrenador
  Future<List<UserProfileModel>> getAthletesForCoach(String coachId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('coach_id', isEqualTo: coachId)
          .get();
      return snap.docs
          .map((doc) => UserProfileModel.fromFirebase(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Error fetching athletes for coach
      return [];
    }
  }

  // Abrir caja de perfiles
  static Future<void> openBox() async {
    await Hive.openBox<UserProfileModel>(_boxName);
  }
}
