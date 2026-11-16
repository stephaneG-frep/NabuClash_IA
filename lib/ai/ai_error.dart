import 'package:dio/dio.dart';

class AiError implements Exception {
  final String message;
  const AiError(this.message);
  @override
  String toString() => message;
  static AiError from(Object error) {
    if (error is AiError) return error;
    if (error is DioException) {
      if (CancelToken.isCancel(error)) return const AiError('Requête annulée.');
      final status = error.response?.statusCode;
      if (status == 401) {
        return const AiError(
          'Clé API invalide ou expirée. Modifie-la dans les réglages.',
        );
      }
      if (status == 403) {
        return const AiError(
          'Accès refusé. Vérifie les autorisations de ta clé et de ton compte.',
        );
      }
      if (status == 404) {
        return const AiError(
          'Modèle indisponible. Actualise la liste ou sélectionne un autre modèle.',
        );
      }
      if (status == 429) {
        return const AiError(
          'Limite de requêtes ou quota dépassé. Vérifie ton crédit API, puis réessaie plus tard.',
        );
      }
      if (status != null && status >= 500) {
        return const AiError(
          'Le fournisseur est momentanément indisponible. Réessaie dans un instant.',
        );
      }
      if (status == 400 || status == 422) {
        return const AiError(
          'Le modèle refuse ce format de requête. Vérifie le modèle ou désactive le mode JSON dans sa configuration.',
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const AiError(
          'Le fournisseur met trop de temps à répondre. Réessaie.',
        );
      }
      return const AiError(
        'Connexion impossible. Vérifie Internet et réessaie.',
      );
    }
    if (error is FormatException || error is TypeError) {
      return const AiError(
        'Réponse du fournisseur illisible. Réessaie ou change de modèle.',
      );
    }
    return const AiError('Cette opération n’a pas abouti. Réessaie.');
  }
}
