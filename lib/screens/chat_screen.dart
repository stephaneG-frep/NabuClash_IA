import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../models/domain.dart';
import '../services/app_state.dart';
import '../services/prompt_builder.dart';
import '../widgets/common.dart';
import '../theme/nabu_theme.dart';
import '../ai/ai_error.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  Conversation? current;
  CancelToken? token;
  String? error;
  String? retryText;
  @override
  void dispose() {
    input.dispose();
    token?.cancel();
    super.dispose();
  }

  Future<void> send({bool retry = false}) async {
    if (token != null) return;
    final text = retry
        ? (current?.messages.lastOrNull?.role == 'user'
              ? current!.messages.last.text
              : retryText ?? '')
        : input.text.trim();
    if (text.isEmpty) return;
    final app = context.read<AppState>();
    final request = CancelToken();
    setState(() {
      token = request;
      error = null;
      retryText = text;
    });
    try {
      current ??= await app.newChat();
      final chat = current!;
      if (!retry) {
        chat.messages.add(Message('user', text));
        input.clear();
        await app.persist();
      }
      final answer = await app.ask(
        PromptBuilder.chat(app.personality, app.language),
        List.of(chat.messages),
        request,
      );
      if (!request.isCancelled) {
        chat.messages.add(Message('assistant', answer));
        await app.persist();
        retryText = null;
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
    current ??= app.chats.firstOrNull;
    final pending = current?.messages.lastOrNull?.role == 'user';
    return PageBody(
      children: [
        const SectionTitle(
          'Clash Chat',
          'Une conversation. Le bon mot, au bon moment.',
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: token == null
                  ? () => guard(context, () async {
                      final c = await app.newChat();
                      setState(() {
                        current = c;
                        error = null;
                        retryText = null;
                      });
                    })
                  : null,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Nouvelle conversation'),
            ),
            if (current != null)
              TextButton.icon(
                onPressed: token == null
                    ? () => guard(context, () async {
                        await app.deleteChat(current!);
                        setState(() {
                          current = app.chats.firstOrNull;
                          error = null;
                          retryText = null;
                        });
                      })
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer'),
              ),
          ],
        ),
        if (app.chats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(current?.id),
              initialValue: current?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Conversations enregistrées',
              ),
              items: app.chats
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: token == null
                  ? (id) => setState(() {
                      current = app.chats.firstWhere((c) => c.id == id);
                      error = null;
                      retryText = null;
                    })
                  : null,
            ),
          ),
        if (current == null || current!.messages.isEmpty)
          const Glass(
            child: Text(
              'Raconte la situation. Nabu t’aide à trouver ton ton et garde le fil de la discussion.',
            ),
          ),
        ...?current?.messages.map(
          (m) => Align(
            alignment: m.role == 'user'
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Glass(
              color: m.role == 'user' ? NabuTheme.violet : NabuTheme.cyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.role == 'user' ? 'TOI' : 'NABU',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: NabuTheme.cyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(m.text),
                  TextActions(m.text),
                ],
              ),
            ),
          ),
        ),
        if (token != null) Busy(cancel: () => token?.cancel()),
        if (error != null) ErrorBox(error!, () => send(retry: true)),
        if (error == null && token == null && pending)
          ErrorBox(
            'Le dernier message attend une réponse. Tu peux reprendre la génération.',
            () => send(retry: true),
          ),
        Text(
          'Messages envoyés à ${app.selected.label}.',
          style: const TextStyle(color: Color(0xffc5bedb)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: input,
          minLines: 1,
          maxLines: 5,
          maxLength: 6000,
          decoration: const InputDecoration(
            labelText: 'Ton message',
            hintText: 'Mon voisin critique toujours ma voiture…',
          ),
        ),
        Row(
          children: [
            VoiceInput(input),
            const Spacer(),
            FilledButton.icon(
              onPressed: token == null
                  ? () {
                      if (pending) {
                        notice(
                          context,
                          'Réessaie le dernier message ou démarre une nouvelle conversation.',
                        );
                        return;
                      }
                      send();
                    }
                  : null,
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      ],
    );
  }
}
