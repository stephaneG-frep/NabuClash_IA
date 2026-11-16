import 'dart:convert';

import '../models/domain.dart';
import '../ai/ai_error.dart';

class ReplyParser {
  static List<Reply> parse(String raw) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$', multiLine: true), '')
        .trim();
    if (s.isEmpty) throw const AiError('Réponse vide. Réessaie.');
    final start = s.indexOf('{'), end = s.lastIndexOf('}');
    if (start >= 0 && end > start) s = s.substring(start, end + 1);
    try {
      final decoded = jsonDecode(s);
      final list = decoded is List ? decoded : decoded['replies'];
      if (list is! List) throw const FormatException();
      final result = <Reply>[];
      for (final item in list) {
        if (item is Map &&
            item['text'] is String &&
            (item['text'] as String).trim().isNotEmpty) {
          result.add(
            Reply(
              (item['text'] as String).trim(),
              item['style'] is String ? item['style'] : 'Répartie',
              item['intensity'] is num
                  ? (item['intensity'] as num).toInt().clamp(1, 5)
                  : 3,
            ),
          );
        }
      }
      if (result.isEmpty) throw const FormatException();
      return result.take(5).toList();
    } catch (_) {
      // A plain-text answer is usable; malformed JSON is never shown as a reply.
      if (s.contains('{') ||
          s.contains('}') ||
          s.startsWith('[') ||
          s.contains('"replies"') ||
          s.contains('"text":')) {
        throw const AiError(
          'Le modèle a renvoyé un JSON incorrect. Réessaie ou désactive le mode JSON.',
        );
      }
      final lines = s
          .split(RegExp(r'\n+'))
          .map(
            (x) =>
                x.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*'), '').trim(),
          )
          .where((x) => x.isNotEmpty && !x.startsWith('#'))
          .toList();
      if (lines.isEmpty) {
        throw const AiError('Réponse non exploitable. Réessaie.');
      }
      return lines.take(5).map((x) => Reply(x, 'Répartie', 3)).toList();
    }
  }
}
