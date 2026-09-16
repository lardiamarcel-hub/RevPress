import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/depense.dart';
import '../models/recette.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Accès à Firestore : profils, invitations, lignes de dépense, dépenses,
/// recettes. Les règles de sécurité (firestore.rules) sont la véritable
/// barrière d'accès ; ce service se contente de former les requêtes.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _depenses => _db.collection('depenses');
  CollectionReference<Map<String, dynamic>> get _recettes => _db.collection('recettes');
  CollectionReference<Map<String, dynamic>> get _utilisateurs => _db.collection('utilisateurs');
  CollectionReference<Map<String, dynamic>> get _invitations => _db.collection('invitations');
  DocumentReference<Map<String, dynamic>> get _lignesDoc => _db.collection('config').doc('lignes');
  DocumentReference<Map<String, dynamic>> get _bootstrapDoc => _db.collection('meta').doc('bootstrap');

  static const lignesParDefaut = [
    'semences',
    'engrais',
    "main-d'œuvre",
    'transport',
    'technicien',
    'équipement',
    'autre',
  ];

  // ---------------------------------------------------------------------
  // Profil utilisateur
  // ---------------------------------------------------------------------

  Stream<UserProfile?> profilStream(String uid) {
    return _utilisateurs.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(uid, doc.data()!);
    });
  }

  Stream<List<UserProfile>> utilisateursStream() {
    return _utilisateurs.orderBy('nom').snapshots().map(
          (snap) => snap.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> definirActif(String uid, bool actif) {
    return _utilisateurs.doc(uid).update({'actif': actif});
  }

  // ---------------------------------------------------------------------
  // Amorçage (premier compte = Promoteur) et invitations
  // ---------------------------------------------------------------------

  /// À appeler avant toute vérification de bootstrap : crée le document
  /// meta/bootstrap s'il n'existe pas encore (promoteur_defini: false).
  Future<void> assurerBootstrapExiste() async {
    final snap = await _bootstrapDoc.get();
    if (!snap.exists) {
      await _bootstrapDoc.set({'promoteur_defini': false});
    }
  }

  Future<bool> promoteurDejaDefini() async {
    final snap = await _bootstrapDoc.get();
    return (snap.data()?['promoteur_defini'] as bool?) == true;
  }

  /// Le tout premier utilisateur à s'inscrire devient Promoteur fondateur.
  /// Écriture atomique : bascule meta/bootstrap à true + création du profil,
  /// verrouillée par les règles Firestore pour n'être possible qu'une fois.
  Future<void> devenirPromoteurFondateur(String uid, String nom) async {
    final batch = _db.batch();
    batch.update(_bootstrapDoc, {'promoteur_defini': true});
    batch.set(
      _utilisateurs.doc(uid),
      UserProfile(uid: uid, nom: nom, role: UserRole.promoteur, actif: true).toMap(),
    );
    await batch.commit();
  }

  Future<Map<String, dynamic>?> chercherInvitation(String email) async {
    final doc = await _invitations.doc(_idEmail(email)).get();
    final data = doc.data();
    if (data == null || data['utilise'] == true) return null;
    return data;
  }

  /// Consomme une invitation valide et crée le profil correspondant.
  Future<void> accepterInvitation(String uid, String email) async {
    final ref = _invitations.doc(_idEmail(email));
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) {
      throw StateError('Invitation introuvable');
    }
    final nom = data['nom'] as String;
    final role = UserRoleX.fromValue(data['role'] as String?);
    final batch = _db.batch();
    batch.update(ref, {'utilise': true, 'role': role.value, 'nom': nom});
    batch.set(
      _utilisateurs.doc(uid),
      UserProfile(uid: uid, nom: nom, role: role, actif: true).toMap(),
    );
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> invitationsEnAttenteStream() {
    return _invitations.where('utilise', isEqualTo: false).snapshots().map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Future<void> creerInvitation({
    required String email,
    required String nom,
    required UserRole role,
  }) {
    return _invitations.doc(_idEmail(email)).set({
      'nom': nom,
      'role': role.value,
      'utilise': false,
      'date_creation': FieldValue.serverTimestamp(),
    });
  }

  Future<void> supprimerInvitation(String email) {
    return _invitations.doc(_idEmail(email)).delete();
  }

  String _idEmail(String email) => email.trim().toLowerCase();

  // ---------------------------------------------------------------------
  // Lignes de dépense (catégories, modifiables par le Superviseur)
  // ---------------------------------------------------------------------

  Stream<List<String>> lignesStream() {
    return _lignesDoc.snapshots().map((doc) {
      final data = doc.data();
      final lignes = data?['lignes'];
      if (lignes == null) return lignesParDefaut;
      return List<String>.from(lignes as List);
    });
  }

  Future<void> definirLignes(List<String> lignes) {
    return _lignesDoc.set({'lignes': lignes});
  }

  // ---------------------------------------------------------------------
  // Dépenses
  // ---------------------------------------------------------------------

  Future<void> ajouterDepense(Depense depense) => _depenses.add(depense.toMap());

  Future<void> modifierDepense(String id, Map<String, dynamic> data) =>
      _depenses.doc(id).update(data);

  Future<void> supprimerDepense(String id) => _depenses.doc(id).delete();

  /// Vue complète (Promoteur / Superviseur), avec filtre de période optionnel.
  Stream<List<Depense>> depensesStream({DateTime? debut, DateTime? fin}) {
    Query<Map<String, dynamic>> q = _depenses.orderBy('date', descending: true);
    if (debut != null) q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut));
    if (fin != null) q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin));
    return q.snapshots().map((s) => s.docs.map(Depense.fromDoc).toList());
  }

  /// Vue restreinte à ses propres saisies (Superviseur, Collaborateur).
  Stream<List<Depense>> mesDepensesStream(String uid) {
    return _depenses
        .where('saisi_par_uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Depense.fromDoc).toList());
  }

  // ---------------------------------------------------------------------
  // Recettes (jamais visibles par un Collaborateur — cf. firestore.rules)
  // ---------------------------------------------------------------------

  Future<void> ajouterRecette(Recette recette) => _recettes.add(recette.toMap());

  Future<void> modifierRecette(String id, Map<String, dynamic> data) =>
      _recettes.doc(id).update(data);

  Future<void> supprimerRecette(String id) => _recettes.doc(id).delete();

  Stream<List<Recette>> recettesStream({DateTime? debut, DateTime? fin}) {
    Query<Map<String, dynamic>> q = _recettes.orderBy('date', descending: true);
    if (debut != null) q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut));
    if (fin != null) q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin));
    return q.snapshots().map((s) => s.docs.map(Recette.fromDoc).toList());
  }

  Stream<List<Recette>> mesRecettesStream(String uid) {
    return _recettes
        .where('saisi_par_uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Recette.fromDoc).toList());
  }
}
