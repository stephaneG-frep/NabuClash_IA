import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../models/domain.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../ai/ai_error.dart';
import '../theme/nabu_theme.dart';

class HomeScreen extends StatefulWidget {
  final bool rescue;
  final Situation? initial;
  const HomeScreen({super.key, this.rescue = false, this.initial});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final text = TextEditingController(), contextText = TextEditingController();
  String style = styles.first, person = people.first, setting = contexts.last;
  double intensity = 3;
  CancelToken? token;
  String? error;
  List<SavedReply> results = [];
  Situation? original;
  String retryModifier = '';
  int? retryIndex;
  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      text.text = s.text;
      contextText.text = s.context;
      style = s.style;
      person = s.person;
      setting = s.setting;
      intensity = s.intensity.toDouble();
    }
  }

  @override
  void dispose() {
    token?.cancel();
    text.dispose();
    contextText.dispose();
    super.dispose();
  }

  Future<void> generate({String modifier = '', int? index}) async {
    if (token != null) return;
    if (text.text.trim().isEmpty && (modifier.isEmpty || original == null)) {
      notice(context, 'Écris ou dicte ce qu’on t’a dit.');
      return;
    }
    final situation = modifier.isNotEmpty && original != null
        ? original!
        : Situation(
            text: text.text.trim(),
            context: contextText.text.trim(),
            style: style,
            person: person,
            setting: setting,
            intensity: intensity.round(),
          );
    final request = CancelToken();
    setState(() {
      token = request;
      error = null;
      retryModifier = modifier;
      retryIndex = index;
    });
    try {
      final data = await context.read<AppState>().generate(
        situation,
        request,
        modifier: modifier,
        previous: modifier.isEmpty ? [] : results.map((x) => x.reply).toList(),
        rescue: widget.rescue && index == null,
        count: index == null ? 5 : 1,
      );
      if (mounted && !request.isCancelled) {
        setState(() {
          original = situation;
          if (index != null && index < results.length) {
            results[index] = data.first;
          } else {
            results = data;
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
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final body = PageBody(
      children: [
        SectionTitle(
          widget.rescue ? '🆘 Sauve-moi !' : "Qu’est-ce qu’on\nt’a dit ?",
          widget.rescue
              ? 'Trois ripostes. Un seul geste.'
              : 'Un peu d’esprit. Juste ce qu’il faut de piquant.',
        ),
        if (!widget.rescue)
          Glass(
            color: NabuTheme.pink,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pris de court ?\nLa répartie express.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const HomeScreen(rescue: true),
                    ),
                  ),
                  child: const Text('🆘 Sauve-moi'),
                ),
              ],
            ),
          ),
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: text,
                minLines: 3,
                maxLines: 7,
                maxLength: 6000,
                decoration: InputDecoration(
                  labelText: widget.rescue
                      ? 'Il/elle vient de dire quoi ?'
                      : 'La petite phrase',
                  hintText: 'Écris, colle ou dicte ce qu’on vient de te dire…',
                ),
              ),
              Wrap(
                children: [
                  VoiceInput(text),
                  TextButton.icon(
                    onPressed: () => guard(context, () async {
                      final clip = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (mounted) {
                        text.text = (clip?.text ?? '').substring(
                          0,
                          (clip?.text ?? '').length.clamp(0, 6000),
                        );
                      }
                    }),
                    icon: const Icon(Icons.content_paste),
                    label: const Text('Coller'),
                  ),
                  TextButton.icon(
                    onPressed: () => text.clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Effacer'),
                  ),
                ],
              ),
              if (!widget.rescue) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: contextText,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    labelText: 'Contexte · facultatif',
                    hintText: 'Devant les autres, sans être méchant…',
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!widget.rescue) ...[
          Text(
            'CHOISIS TON ÉNERGIE',
            style: const TextStyle(
              color: NabuTheme.cyan,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: style == v,
                    onSelected: (_) => setState(() => style = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          Glass(
            color: NabuTheme.pink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌶️ Niveau de piquant · ${intensity.round()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: intensity,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: const [
                    'Gentil',
                    'Taquin',
                    'Piquant',
                    'Corsé',
                    'Sans détour',
                  ][intensity.round() - 1],
                  semanticFormatterCallback: (v) => '${v.round()} sur 5',
                  onChanged: (v) => setState(() => intensity = v),
                ),
                Text(
                  const [
                    'Gentil',
                    'Taquin',
                    'Piquant',
                    'Corsé',
                    'Sans détour',
                  ][intensity.round() - 1],
                ),
                const Text(
                  'De l’esprit, jamais de menaces.',
                  style: TextStyle(color: Color(0xffc5bedb)),
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: const Text('Adapter au contexte social'),
            children: [
              selectField(
                'Interlocuteur',
                person,
                people,
                (v) => setState(() => person = v),
              ),
              selectField(
                'Cadre',
                setting,
                contexts,
                (v) => setState(() => setting = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Text(
          'Tes textes seront envoyés uniquement à ${app.selected.label}.',
          style: const TextStyle(color: Color(0xffc5bedb)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: token == null ? () => generate() : null,
          icon: const Icon(Icons.bolt),
          label: Text(
            widget.rescue
                ? 'Trouver mes 3 ripostes'
                : 'Trouve-moi une répartie',
          ),
        ),
        const SizedBox(height: 20),
        if (token != null) Busy(cancel: () => token?.cancel()),
        if (error != null)
          ErrorBox(
            error!,
            () => generate(modifier: retryModifier, index: retryIndex),
          ),
        if (results.isNotEmpty) ...[
          const SectionTitle(
            'À toi de jouer.',
            'Choisis celle qui te ressemble.',
          ),
          ...results.asMap().entries.map(
            (e) => ReplyCard(
              e.value,
              regenerate: token == null
                  ? () => generate(
                      modifier:
                          'Régénère uniquement la réponse ${e.key + 1}, avec le même style mais une idée nouvelle.',
                      index: e.key,
                    )
                  : null,
            ),
          ),
          const Text(
            'Ajuster la répartie',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modifiers
                .map(
                  (m) => ActionChip(
                    label: Text(m),
                    onPressed: token == null
                        ? () => generate(modifier: m)
                        : null,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
    return widget.rescue || widget.initial != null
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                widget.rescue ? 'Mode express' : 'Réutiliser une situation',
              ),
            ),
            body: body,
          )
        : body;
  }
}
