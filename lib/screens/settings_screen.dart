import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../models/domain.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../theme/nabu_theme.dart';
import '../ai/ai_error.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageBody(
      children: [
        const SectionTitle('À ta façon.', 'Ton IA. Ton style. Tes règles.'),
        Glass(
          child: Column(
            children: [
              selectField(
                'Personnalité NabuClash',
                app.personality,
                personalities,
                (v) => guard(context, () async {
                  app.personality = v;
                  await app.persist();
                }),
              ),
              selectField(
                'Langue des réponses',
                app.language,
                ['Français', 'English', 'Español'],
                (v) => guard(context, () async {
                  app.language = v;
                  await app.persist();
                }),
              ),
            ],
          ),
        ),
        Text(
          'Fournisseurs IA',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Une clé API personnelle est nécessaire. Les abonnements aux applications de chat ne remplacent pas les crédits API. Le test de connexion effectue un petit appel facturable.',
        ),
        const SizedBox(height: 18),
        ...ProviderId.values.map(
          (p) => Glass(
            color: app.selected == p ? NabuTheme.cyan : NabuTheme.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      p.symbol,
                      style: const TextStyle(
                        fontSize: 32,
                        color: NabuTheme.cyan,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        p.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (app.selected == p)
                      const Icon(Icons.check_circle, color: NabuTheme.cyan),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${app.configured.contains(p) ? 'Configuré · clé masquée' : 'Non configuré'}${app.selected == p ? ' · Par défaut' : ''}',
                ),
                if ((app.models[p] ?? '').isNotEmpty) Text(app.models[p]!),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ProviderEditor(p),
                        ),
                      ),
                      child: Text(
                        app.configured.contains(p)
                            ? 'Modifier / Tester'
                            : 'Configurer',
                      ),
                    ),
                    if (app.configured.contains(p)) ...[
                      TextButton(
                        onPressed: () => guard(context, () => app.select(p)),
                        child: const Text('Définir par défaut'),
                      ),
                      TextButton(
                        onPressed: () => guard(context, () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Supprimer la clé API ?'),
                              content: Text(
                                'La clé ${p.label} sera effacée du stockage sécurisé de cet appareil.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await app.removeProvider(p);
                        }),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Glass(
          color: NabuTheme.cyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confidentialité',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Les textes soumis et le contexte utile sont envoyés uniquement au fournisseur sélectionné. Les conversations restent sur cet appareil. Les clés sont conservées dans le stockage sécurisé Android. Aucune télémétrie intégrée.\n\nLa dictée dépend du service vocal Android : celui-ci peut traiter l’audio en ligne selon tes réglages. La synthèse vocale dépend des voix installées.',
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Comment utiliser NabuClash ?'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'NABUCLASH AI · 1.0.0\nL’esprit avant l’insulte.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class ProviderEditor extends StatefulWidget {
  final ProviderId provider;
  const ProviderEditor(this.provider, {super.key});
  @override
  State<ProviderEditor> createState() => _ProviderEditorState();
}

class _ProviderEditorState extends State<ProviderEditor> {
  final keyInput = TextEditingController(), model = TextEditingController();
  bool obscure = true, json = true, loading = true;
  List<String> models = [];
  CancelToken? token;
  String? error, status;
  String lastAction = 'models';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final app = context.read<AppState>();
      final key = await app.secrets.read(widget.provider.name);
      if (mounted) {
        setState(() {
          keyInput.text = key ?? '';
          model.text = app.models[widget.provider] ?? '';
          json = app.jsonModes[widget.provider] ?? true;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Impossible de lire le stockage sécurisé.';
        });
      }
    }
  }

  @override
  void dispose() {
    token?.cancel();
    keyInput.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> action(String kind) async {
    if (token != null) return;
    if (keyInput.text.trim().isEmpty) {
      notice(context, 'Saisis ta clé API.');
      return;
    }
    final request = CancelToken();
    setState(() {
      token = request;
      error = null;
      status = null;
      lastAction = kind;
    });
    try {
      final app = context.read<AppState>();
      final provider = app.registry.get(widget.provider);
      if (kind == 'models') {
        final list = await provider.models(keyInput.text.trim(), request);
        if (mounted) {
          setState(() {
            models = list;
            status = widget.provider == ProviderId.perplexity
                ? 'Catalogue Sonar documenté. Utilise Tester pour valider la clé.'
                : '${list.length} modèles récupérés. Choisis un modèle de conversation texte.';
          });
        }
      } else {
        await provider.test(keyInput.text.trim(), model.text.trim(), request);
        if (mounted) {
          setState(() => status = 'Connexion réussie : le modèle a répondu.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = AiError.from(e).message);
    } finally {
      if (mounted) setState(() => token = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.provider.label)),
    body: PageBody(
      children: [
        const SectionTitle(
          'Branche ton IA.',
          'La clé reste protégée sur ton appareil.',
        ),
        if (loading)
          const LinearProgressIndicator()
        else ...[
          TextField(
            controller: keyInput,
            obscureText: obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Clé API',
              suffixIcon: IconButton(
                tooltip: obscure ? 'Afficher la clé' : 'Masquer la clé',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: model,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Identifiant du modèle',
              hintText: 'Actualise la liste ou saisis un identifiant officiel',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: token == null ? () => action('models') : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Récupérer les modèles'),
          ),
          if (models.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Modèles disponibles',
                ),
                items: models
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) model.text = v;
                },
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Format JSON natif'),
            subtitle: const Text(
              'Utilisé pour les réparties lorsque l’adaptateur le prend en charge. Désactive-le si ton modèle le refuse.',
            ),
            value: json,
            onChanged: (v) => setState(() => json = v),
          ),
          TextButton.icon(
            onPressed: token == null ? () => action('test') : null,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Tester la connexion'),
          ),
          if (token != null) Busy(cancel: () => token?.cancel()),
          if (error != null) ErrorBox(error!, () => action(lastAction)),
          if (status != null)
            Glass(color: NabuTheme.cyan, child: Text(status!)),
          FilledButton(
            onPressed: token == null
                ? () => guard(context, () async {
                    await context.read<AppState>().configure(
                      widget.provider,
                      keyInput.text,
                      model.text,
                      json,
                    );
                    if (context.mounted) {
                      notice(context, 'Configuration enregistrée.');
                      Navigator.pop(context);
                    }
                  })
                : null,
            child: const Text('Enregistrer'),
          ),
        ],
      ],
    ),
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mode d’emploi')),
    body: const PageBody(
      children: [
        SectionTitle('Du tact au tac.', 'Comment utiliser NabuClash ?'),
        Glass(
          child: Text(
            '1. Réglages → Fournisseurs IA : ajoute ta clé API.\n2. Récupère les modèles et choisis un modèle texte.\n3. Teste, enregistre et définis le fournisseur par défaut.\n4. Écris, colle ou dicte ce qu’on t’a dit.\n5. Choisis ton style et précise le contexte.\n6. Règle le piquant de 1 à 5.\n7. Lance la génération.\n8. Copie, écoute, partage ou ajoute une réponse aux favoris.',
          ),
        ),
        Glass(
          child: Text(
            '🆘 Sauve-moi : trois réponses express, de tranquille à audacieuse.\n\n💬 Clash Chat : une conversation qui conserve le contexte ; retrouve ou supprime les discussions enregistrées.\n\n🥋 Dojo : entraîne-toi contre un personnage fictif et obtiens un retour descriptif.\n\n⭐ Favoris : retrouve tes phrases et consulte l’historique, avec recherche et réutilisation.\n\n⚙️ Fournisseurs : chaque clé et modèle se configurent séparément. Un seul fournisseur reçoit chaque requête.',
          ),
        ),
        Glass(
          child: Text(
            'Les appels API peuvent être facturés par le fournisseur. Aucun abonnement ChatGPT, Claude ou autre n’est automatiquement une clé API.\n\nUne erreur de quota ? Vérifie le crédit du compte API. Un modèle disparu ? Actualise la liste. Le micro refusé ? Autorise-le dans les paramètres Android.\n\nL’annulation coupe l’attente réseau côté application ; le fournisseur peut avoir déjà traité et facturé la requête.',
          ),
        ),
      ],
    ),
  );
}
