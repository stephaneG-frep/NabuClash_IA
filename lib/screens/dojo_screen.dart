import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../models/domain.dart';
import '../services/app_state.dart';
import '../services/prompt_builder.dart';
import '../widgets/common.dart';
import '../ai/ai_error.dart';

class DojoScreen extends StatefulWidget {
  const DojoScreen({super.key});
  @override
  State<DojoScreen> createState() => _DojoScreenState();
}

class _DojoScreenState extends State<DojoScreen> {
  static const characters = [
    'Ami moqueur',
    'Collègue sarcastique',
    'Personne arrogante',
    'Troll Internet',
    'Personnage ironique',
    'Adversaire verbal fictif',
  ];
  String character = characters.first, remark = '', review = '';
  final answer = TextEditingController();
  CancelToken? token;
  String? error;
  bool retryReview = false;
  @override
  void dispose() {
    answer.dispose();
    token?.cancel();
    super.dispose();
  }

  Future<void> run(bool evaluate) async {
    if (token != null) return;
    if (evaluate && answer.text.trim().isEmpty) {
      notice(context, 'À toi d’inventer une répartie avant l’analyse.');
      return;
    }
    final request = CancelToken();
    final app = context.read<AppState>();
    setState(() {
      token = request;
      error = null;
      retryReview = evaluate;
    });
    try {
      final response = await app.ask(
        PromptBuilder.system(app.personality, app.language),
        [
          Message(
            'user',
            evaluate
                ? PromptBuilder.dojoReview(remark, answer.text.trim())
                : PromptBuilder.dojoStart(character),
          ),
        ],
        request,
      );
      if (mounted && !request.isCancelled) {
        setState(() {
          if (evaluate) {
            review = response;
          } else {
            remark = response;
            review = '';
            answer.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = AiError.from(e).message);
    } finally {
      if (mounted) setState(() => token = null);
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SectionTitle(
        '🥋 Le Dojo',
        'La répartie, ça se travaille. Entre dans l’arène.',
      ),
      const Glass(
        child: Text(
          'Un personnage fictif te lance une pique. Réponds avec tes propres mots ; Nabu analyse ton esprit, ton rythme et ton élégance.',
        ),
      ),
      selectField(
        'Ton partenaire d’entraînement',
        character,
        characters,
        (v) => setState(() => character = v),
      ),
      FilledButton.icon(
        onPressed: token == null ? () => run(false) : null,
        icon: const Icon(Icons.sports_martial_arts),
        label: Text(
          remark.isEmpty ? 'Commencer l’exercice' : 'Nouvel exercice',
        ),
      ),
      const SizedBox(height: 20),
      if (remark.isNotEmpty) ...[
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SelectableText(remark),
              TextActions(remark),
            ],
          ),
        ),
        TextField(
          controller: answer,
          minLines: 2,
          maxLines: 5,
          maxLength: 3000,
          decoration: const InputDecoration(
            labelText: 'Ta répartie',
            hintText: 'À toi de jouer…',
          ),
        ),
        VoiceInput(answer),
        FilledButton.tonal(
          onPressed: token == null ? () => run(true) : null,
          child: const Text('Analyser ma répartie'),
        ),
        const SizedBox(height: 20),
      ],
      if (token != null) Busy(cancel: () => token?.cancel()),
      if (error != null) ErrorBox(error!, () => run(retryReview)),
      if (review.isNotEmpty)
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LE RETOUR DE NABU',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              SelectableText(review),
              TextActions(review),
            ],
          ),
        ),
    ],
  );
}
