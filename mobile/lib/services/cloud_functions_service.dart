import 'package:cloud_functions/cloud_functions.dart';

class RefreshResult {
  const RefreshResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

/// Déclenche les actions serveur qui alimentent la revue de presse :
/// import de la liste de sources et collecte immédiate. `functions` est
/// `null` quand Firebase n'a pas pu être initialisé — dans ce cas, chaque
/// action renvoie un message explicite plutôt que de planter.
class CloudFunctionsService {
  CloudFunctionsService({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  /// Amorce la collection `sources` si elle est vide (idempotent, rapide,
  /// aucun appel à l'IA).
  Future<RefreshResult> seedSources() => _call(
        'seedSources',
        onSuccess: (data) {
          final count = (data['sourcesAjoutees'] as num?)?.toInt() ?? 0;
          return count > 0 ? '$count sources importées avec succès.' : 'Les sources étaient déjà importées.';
        },
        failurePrefix: "Échec de l'import des sources",
      );

  /// Relance immédiatement la collecte + classification + digest, sans
  /// attendre la prochaine collecte planifiée. Peut prendre plusieurs
  /// minutes (chaque article est classé par l'IA).
  Future<RefreshResult> manualRefresh() => _call(
        'manualRefresh',
        timeout: const Duration(minutes: 9),
        onSuccess: (data) {
          final count = (data['articlesCollectes'] as num?)?.toInt() ?? 0;
          return count > 0
              ? '$count nouveaux articles collectés, digest mis à jour.'
              : "Aucun nouvel article pour l'instant.";
        },
        failurePrefix: "Échec de l'actualisation",
      );

  Future<RefreshResult> _call(
    String name, {
    required String Function(Map<Object?, Object?> data) onSuccess,
    required String failurePrefix,
    Duration? timeout,
  }) async {
    final functions = _functions;
    if (functions == null) {
      return const RefreshResult(
        ok: false,
        message: "Backend non connecté : cette action nécessite qu'un projet Firebase soit configuré.",
      );
    }
    try {
      final callable = functions.httpsCallable(
        name,
        options: timeout != null ? HttpsCallableOptions(timeout: timeout) : null,
      );
      final result = await callable.call();
      final data = (result.data as Map?)?.cast<Object?, Object?>() ?? const {};
      return RefreshResult(ok: true, message: onSuccess(data));
    } on FirebaseFunctionsException catch (e) {
      return RefreshResult(ok: false, message: '$failurePrefix : ${e.message ?? e.code}');
    } catch (e) {
      return RefreshResult(ok: false, message: '$failurePrefix : $e');
    }
  }
}
