import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../models/domain.dart';
import '../storage/local_store.dart';
import '../ai/ai_provider.dart';
import '../ai/ai_error.dart';
import 'prompt_builder.dart';
import 'reply_parser.dart';

class AppState extends ChangeNotifier {
  final LocalStore store;
  final SecretStore secrets;
  final ProviderRegistry registry;
  AppState(this.store, this.secrets, {ProviderRegistry? providers})
    : registry = providers ?? ProviderRegistry();
  ProviderId selected = ProviderId.openai;
  String personality = personalities.first, language = 'Français';
  final Map<ProviderId, String> models = {};
  final Map<ProviderId, bool> jsonModes = {};
  final Set<ProviderId> configured = {};
  final List<SavedReply> history = [];
  final List<Conversation> chats = [];
  String? loadError;
  Future<void> initialize() async {
    try {
      final j = store.load();
      selected = ProviderId.values.firstWhere(
        (v) => v.name == j['selected'],
        orElse: () => ProviderId.openai,
      );
      personality = j['personality'] as String? ?? personalities.first;
      language = j['language'] as String? ?? 'Français';
      for (final p in ProviderId.values) {
        models[p] = j['models']?[p.name] as String? ?? '';
        jsonModes[p] = j['jsonModes']?[p.name] as bool? ?? true;
        if ((await secrets.read(p.name))?.isNotEmpty == true) configured.add(p);
      }
      history.addAll(
        (j['history'] as List? ?? []).map(
          (x) => SavedReply.fromJson(Map<String, dynamic>.from(x)),
        ),
      );
      chats.addAll(
        (j['chats'] as List? ?? []).map(
          (x) => Conversation.fromJson(Map<String, dynamic>.from(x)),
        ),
      );
    } catch (_) {
      loadError = 'Certaines données locales ne sont pas lisibles. Vérifie tes réglages avant de continuer.';
    }
    notifyListeners();
  }

  Future<void> persist() async {
    try {
      await store.save({
        'selected': selected.name,
        'personality': personality,
        'language': language,
        'models': {for (final p in models.keys) p.name: models[p]},
        'jsonModes': {for (final p in jsonModes.keys) p.name: jsonModes[p]},
        'history': history.map((x) => x.toJson()).toList(),
        'chats': chats.map((x) => x.toJson()).toList(),
      });
    } catch (_) {
      throw const AiError(
        'Impossible d’enregistrer les données locales. Vérifie l’espace disponible.',
      );
    }
    notifyListeners();
  }

  Future<void> configure(
    ProviderId p,
    String key,
    String model,
    bool json,
  ) async {
    if (key.trim().isEmpty || model.trim().isEmpty) {
      throw const AiError('Renseigne la clé API et le modèle.');
    }
    await secrets.write(p.name, key.trim());
    models[p] = model.trim();
    jsonModes[p] = json;
    configured.add(p);
    await persist();
  }

  Future<void> removeProvider(ProviderId p) async {
    await secrets.delete(p.name);
    configured.remove(p);
    models.remove(p);
    await persist();
  }

  Future<void> select(ProviderId p) async {
    if (!configured.contains(p)) {
      throw const AiError('Configure ce fournisseur avant de le sélectionner.');
    }
    selected = p;
    await persist();
  }

  Future<String> ask(
    String system,
    List<Message> messages,
    CancelToken token, {
    bool structured = false,
  }) async {
    final p = selected;
    final key = await secrets.read(p.name) ?? '';
    if (token.isCancelled) throw const AiError('Requête annulée.');
    return registry
        .get(p)
        .conversation(
          key: key,
          model: models[p] ?? '',
          system: system,
          messages: messages,
          token: token,
          structured: structured && (jsonModes[p] ?? true),
        );
  }

  Future<List<SavedReply>> generate(
    Situation s,
    CancelToken token, {
    String modifier = '',
    List<Reply> previous = const [],
    bool rescue = false,
    int count = 5,
  }) async {
    final p = selected, model = models[selected] ?? '';
    final text = await ask(
      PromptBuilder.system(personality, language),
      [
        Message(
          'user',
          PromptBuilder.replies(
            s,
            modifier: modifier,
            previous: previous,
            rescue: rescue,
            count: count,
          ),
        ),
      ],
      token,
      structured: true,
    );
    if (token.isCancelled) throw const AiError('Requête annulée.');
    final now = DateTime.now();
    final replies = ReplyParser.parse(text).take(rescue ? 3 : count).toList();
    final saved = [
      for (var i = 0; i < replies.length; i++)
        SavedReply(
          id: '${now.microsecondsSinceEpoch}-$i',
          date: now.toIso8601String(),
          provider: p.label,
          model: model,
          situation: s,
          reply: replies[i],
        ),
    ];
    history.insertAll(0, saved);
    await persist();
    return saved;
  }

  Future<void> favorite(SavedReply r) async {
    r.favorite = !r.favorite;
    await persist();
  }

  Future<void> deleteReply(SavedReply r) async {
    history.removeWhere((x) => x.id == r.id);
    await persist();
  }

  Future<Conversation> newChat() async {
    final c = Conversation(DateTime.now().microsecondsSinceEpoch.toString());
    chats.insert(0, c);
    await persist();
    return c;
  }

  Future<void> deleteChat(Conversation c) async {
    chats.remove(c);
    await persist();
  }
}
