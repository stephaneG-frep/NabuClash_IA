import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../models/domain.dart';
import '../ai/ai_error.dart';
import '../theme/nabu_theme.dart';

void notice(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

Future<void> guard(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) notice(context, AiError.from(e).message);
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final Color color;
  const Glass({super.key, required this.child, this.color = NabuTheme.violet});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .15), const Color(0xff17152b)],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color.withValues(alpha: .25)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .05), blurRadius: 24),
      ],
    ),
    child: child,
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const SectionTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24, top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Color(0xffc5bedb))),
      ],
    ),
  );
}

class Busy extends StatefulWidget {
  final VoidCallback cancel;
  const Busy({super.key, required this.cancel});
  @override
  State<Busy> createState() => _BusyState();
}

class _BusyState extends State<Busy> {
  static const messages = [
    'Chargement du sarcasme…',
    'Nabu cherche la petite phrase…',
    'Affûtage de la répartie…',
    'Préparation de la riposte…',
    'Dosage du piquant…',
    'Recherche d’une réponse qui claque…',
  ];
  late Timer timer;
  int index = Random().nextInt(messages.length);
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => index = (index + 1) % messages.length);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Glass(
    color: NabuTheme.cyan,
    child: Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(messages[index], key: ValueKey(index)),
          ),
        ),
        TextButton.icon(
          onPressed: widget.cancel,
          icon: const Icon(Icons.close),
          label: const Text('Annuler'),
        ),
      ],
    ),
  );
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorBox(this.message, this.retry, {super.key});
  @override
  Widget build(BuildContext context) => Glass(
    color: NabuTheme.pink,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(liveRegion: true, child: Text(message)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

class VoiceInput extends StatefulWidget {
  final TextEditingController controller;
  const VoiceInput(this.controller, {super.key});
  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  final speech = SpeechToText();
  bool listening = false;
  @override
  void dispose() {
    speech.cancel();
    super.dispose();
  }

  Future<void> toggle() async {
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    try {
      final ok = await speech.initialize(
        onStatus: (s) {
          if (mounted) setState(() => listening = s == 'listening');
        },
        onError: (e) {
          if (mounted) {
            setState(() => listening = false);
            notice(
              context,
              'Dictée interrompue. Vérifie le micro, Internet et le service vocal Android.',
            );
          }
        },
      );
      if (!mounted) return;
      if (!ok) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Activer la dictée'),
            content: const Text(
              'Autorise le microphone dans Paramètres Android → Applications → NabuClash AI → Autorisations. Un service de reconnaissance vocale et sa langue doivent être installés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  openAppSettings();
                },
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
          ),
        );
        return;
      }
      final locales = await speech.locales();
      final french = locales
          .where((l) => l.localeId.startsWith('fr'))
          .firstOrNull;
      await speech.listen(
        onResult: (r) {
          if (mounted) {
            widget.controller.text = r.recognizedWords;
            widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length,
            );
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: french?.localeId,
          partialResults: true,
          cancelOnError: true,
        ),
      );
      if (mounted) setState(() => listening = true);
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Dictée indisponible sur cet appareil. Tu peux écrire ou coller ton texte.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: toggle,
    icon: Icon(listening ? Icons.stop_circle : Icons.mic_none),
    label: Text(listening ? 'Arrêter' : 'Dicter'),
  );
}

class TextActions extends StatefulWidget {
  final String text;
  const TextActions(this.text, {super.key});
  @override
  State<TextActions> createState() => _TextActionsState();
}

class _TextActionsState extends State<TextActions> {
  final tts = FlutterTts();
  bool speaking = false;
  @override
  void initState() {
    super.initState();
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });
    tts.setErrorHandler((_) {
      if (mounted) {
        setState(() => speaking = false);
        notice(
          context,
          'Lecture indisponible. Vérifie le moteur vocal Android.',
        );
      }
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: [
      IconButton(
        tooltip: 'Copier',
        onPressed: () => guard(context, () async {
          await Clipboard.setData(ClipboardData(text: widget.text));
          if (context.mounted) notice(context, 'Copié !');
        }),
        icon: const Icon(Icons.copy_rounded),
      ),
      IconButton(
        tooltip: 'Partager',
        onPressed: () => guard(context, () async {
          await SharePlus.instance.share(ShareParams(text: widget.text));
        }),
        icon: const Icon(Icons.share_outlined),
      ),
      IconButton(
        tooltip: speaking ? 'Arrêter la lecture' : 'Lire à voix haute',
        onPressed: () => guard(context, () async {
          if (speaking) {
            await tts.stop();
            if (mounted) setState(() => speaking = false);
          } else {
            final lang = context.read<AppState>().language;
            await tts.setLanguage(
              lang == 'English'
                  ? 'en-US'
                  : lang == 'Español'
                  ? 'es-ES'
                  : 'fr-FR',
            );
            await tts.setSpeechRate(.48);
            final result = await tts.speak(widget.text);
            if (context.mounted) {
              setState(() => speaking = result == 1);
              if (result != 1) {
                notice(
                  context,
                  'Installe une voix dans les réglages de synthèse vocale Android.',
                );
              }
            }
          }
        }),
        icon: Icon(
          speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        ),
      ),
    ],
  );
}

class ReplyCard extends StatelessWidget {
  final SavedReply saved;
  final VoidCallback? regenerate, reuse, delete;
  const ReplyCard(
    this.saved, {
    super.key,
    this.regenerate,
    this.reuse,
    this.delete,
  });
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return Glass(
      color: saved.reply.intensity >= 4 ? NabuTheme.pink : NabuTheme.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${saved.reply.style} · ${saved.reply.intensity}/5',
            style: const TextStyle(
              color: NabuTheme.cyan,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            '« ${saved.reply.text} »',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextActions(saved.reply.text),
              IconButton(
                tooltip: saved.favorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: () => guard(
                  context,
                  () => context.read<AppState>().favorite(saved),
                ),
                icon: Icon(
                  saved.favorite ? Icons.star : Icons.star_border,
                  color: NabuTheme.pink,
                ),
              ),
              if (regenerate != null)
                IconButton(
                  tooltip: 'Régénérer cette réponse',
                  onPressed: regenerate,
                  icon: const Icon(Icons.refresh),
                ),
              if (reuse != null)
                IconButton(
                  tooltip: 'Réutiliser la situation',
                  onPressed: reuse,
                  icon: const Icon(Icons.replay),
                ),
              if (delete != null)
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: delete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          Text(
            saved.provider,
            style: const TextStyle(fontSize: 12, color: Color(0xffbab2cf)),
          ),
        ],
      ),
    );
  }
}

Widget selectField(
  String label,
  String value,
  List<String> items,
  ValueChanged<String> change,
) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: DropdownButtonFormField<String>(
    initialValue: items.contains(value) ? value : items.first,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList(),
    onChanged: (v) {
      if (v != null) change(v);
    },
  ),
);
