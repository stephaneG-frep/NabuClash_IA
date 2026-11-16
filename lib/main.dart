import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_state.dart';
import 'storage/local_store.dart';
import 'theme/nabu_theme.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/dojo_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(
    LocalStore(await SharedPreferences.getInstance()),
    SecureSecrets(),
  );
  await state.initialize();
  runApp(ChangeNotifierProvider.value(value: state, child: const NabuApp()));
}

class NabuApp extends StatelessWidget {
  const NabuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NabuClash AI',
    debugShowCheckedModeBanner: false,
    theme: NabuTheme.dark,
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: NabuTheme.cyan),
              SizedBox(width: 8),
              Text(
                'NABU',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                'CLASH',
                style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 2),
              ),
              SizedBox(width: 6),
              Text('AI', style: TextStyle(fontSize: 12, color: NabuTheme.pink)),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mode d’emploi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
            ),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (app.loadError != null)
              MaterialBanner(
                content: Text(app.loadError!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => app.loadError = null),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: index,
                children: const [
                  HomeScreen(),
                  ChatScreen(),
                  DojoScreen(),
                  LibraryScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Clash Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_martial_arts),
            label: 'Dojo',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            label: 'Favoris',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Réglages'),
        ],
      ),
    );
  }
}
