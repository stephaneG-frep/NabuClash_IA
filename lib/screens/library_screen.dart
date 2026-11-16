import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool favorites = true;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.history
        .where(
          (r) =>
              (!favorites || r.favorite) &&
              ('${r.reply.text} ${r.situation.text} ${r.reply.style}')
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return PageBody(
      children: [
        const SectionTitle(
          'Tes meilleures\nrépliques.',
          'Les mots passent. Les bonnes phrases restent.',
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Favoris'),
              icon: Icon(Icons.star_outline),
            ),
            ButtonSegment(
              value: false,
              label: Text('Historique'),
              icon: Icon(Icons.history),
            ),
          ],
          selected: {favorites},
          onSelectionChanged: (s) => setState(() => favorites = s.first),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Rechercher',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 20),
        if (items.isEmpty)
          const Glass(
            child: Text(
              'Rien ici pour le moment. Génère une répartie, puis touche l’étoile pour la retrouver.',
            ),
          ),
        ...items.map(
          (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.situation.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ReplyCard(
                r,
                reuse: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HomeScreen(initial: r.situation),
                  ),
                ),
                delete: () => guard(context, () => app.deleteReply(r)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
