// Controlled network fixtures exist only in tests. Production always calls APIs.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabuclash_ai/ai/ai_provider.dart';
import 'package:nabuclash_ai/main.dart';
import 'package:nabuclash_ai/models/domain.dart';
import 'package:nabuclash_ai/services/app_state.dart';
import 'package:nabuclash_ai/storage/local_store.dart';

import 'core_test.dart' show MemorySecrets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppState state;
  late List<RequestOptions> requests;
  late GlobalKey capture;

  setUp(() async {
    if (const bool.fromEnvironment('NABU_SCREENSHOTS')) {
      final sdk = Platform.environment['FLUTTER_ROOT'];
      if (sdk != null) {
        final font = File(
          '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        );
        if (await font.exists()) {
          final loader = FontLoader('Roboto')
            ..addFont(font.readAsBytes().then((b) => ByteData.sublistView(b)));
          await loader.load();
        }
      }
    }
    if (const bool.fromEnvironment('NABU_SCREENSHOTS')) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
    requests = [];
    capture = GlobalKey();
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          requests.add(r);
          if (r.method == 'GET') {
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'data': [
                    {'id': 'fixture-model'},
                  ],
                },
              ),
            );
            return;
          }
          final messages = r.data['messages'] as List;
          final prompt = messages.last['content'] as String;
          String content;
          if (prompt.startsWith('Produis')) {
            final count = prompt.startsWith('Produis 3')
                ? 3
                : prompt.startsWith('Produis 1')
                ? 1
                : 5;
            content = jsonEncode({
              'replies': List.generate(
                count,
                (i) => {
                  'text': 'Réponse du transport de test ${requests.length}-$i',
                  'style': 'Subtile',
                  'intensity': 3,
                },
              ),
            });
          } else if (prompt.startsWith('DOJO : joue')) {
            content = 'Remarque fictive de test pour le Dojo.';
          } else if (prompt.startsWith('DOJO : analyse')) {
            content = 'Humour : clair. Originalité : bonne. Clarté, agressivité, subtilité, efficacité et élégance : analyse de test. Alternatives : une, deux, trois.';
          } else {
            content =
                'Message de test ${requests.length} conservant le contexte.';
          }
          h.resolve(
            Response(
              requestOptions: r,
              statusCode: 200,
              data: {
                'choices': [
                  {
                    'message': {'content': content},
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    state = AppState(
      LocalStore(await SharedPreferences.getInstance()),
      MemorySecrets(),
      providers: ProviderRegistry(dio),
    );
    await state.initialize();
    await state.configure(
      ProviderId.openai,
      'fixture-key',
      'fixture-model',
      true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => 1,
        );
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: RepaintBoundary(key: capture, child: const NabuApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('NABU_SCREENSHOTS')) return;
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/qa');
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
  }

  testWidgets(
    'Home, five results, favorite, modifier, regenerate, search and reuse',
    (tester) async {
      await start(tester);
      await snap(tester, 'home');
      await tester.enterText(
        find.byType(TextField).first,
        'Ma voiture date de la préhistoire',
      );
      await tap(tester, find.text('Trouve-moi une répartie'));
      expect(state.history.length, 5);
      final first = state.history.first;
      await tap(tester, find.byTooltip('Ajouter aux favoris').first);
      expect(first.favorite, true);
      await snap(tester, 'results');
      await tap(tester, find.text('⚡ Plus court'));
      expect(state.history.length, 10);
      expect(
        jsonEncode(requests.last.data),
        contains('Ma voiture date de la préhistoire'),
      );
      expect(jsonEncode(requests.last.data), contains('Plus court'));
      await tap(tester, find.byTooltip('Régénérer cette réponse').first);
      expect(state.history.length, 11);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Favoris'));
      expect(find.text('« ${first.reply.text} »'), findsOneWidget);
      await tap(tester, find.byTooltip('Réutiliser la situation'));
      expect(
        find.widgetWithText(TextField, 'Ma voiture date de la préhistoire'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'introuvable');
      await tester.pumpAndSettle();
      expect(find.textContaining('Rien ici'), findsOneWidget);
    },
  );

  testWidgets('Rescue produces three replies and retains original situation', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, find.text('🆘 Sauve-moi'));
    await tester.enterText(find.byType(TextField).first, 'Une pique urgente');
    await tap(tester, find.text('Trouver mes 3 ripostes'));
    expect(state.history.length, 3);
    expect(jsonEncode(requests.last.data), contains('Réponse audacieuse'));
    expect(
      state.history.every((r) => r.situation.text == 'Une pique urgente'),
      true,
    );
  });

  testWidgets(
    'Chat sends history, persists, starts and deletes conversations',
    (tester) async {
      await start(tester);
      await tap(
        tester,
        find.widgetWithText(NavigationDestination, 'Clash Chat'),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'Mon voisin critique ma voiture',
      );
      await tap(tester, find.text('Envoyer'));
      expect(state.chats.single.messages.length, 2);
      await tester.enterText(
        find.byType(TextField).first,
        'Avec humour sans méchanceté',
      );
      await tap(tester, find.text('Envoyer'));
      expect((requests.last.data['messages'] as List).length, 4);
      expect(
        jsonEncode(requests.last.data),
        contains('Mon voisin critique ma voiture'),
      );
      await snap(tester, 'chat');
      final restored = AppState(state.store, state.secrets);
      await restored.initialize();
      expect(restored.chats.single.messages.length, 4);
      await tap(tester, find.text('Nouvelle conversation'));
      expect(state.chats.length, 2);
      await tap(tester, find.text('Supprimer'));
      expect(state.chats.length, 1);
    },
  );

  testWidgets('Dojo generates an exercise then analyzes the user answer', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, find.widgetWithText(NavigationDestination, 'Dojo'));
    await tap(tester, find.text('Commencer l’exercice'));
    expect(find.text('Remarque fictive de test pour le Dojo.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'Ma réponse originale',
    );
    await tap(tester, find.text('Analyser ma répartie'));
    expect(jsonEncode(requests.last.data), contains('Ma réponse originale'));
    expect(find.textContaining('Humour : clair.'), findsOneWidget);
    await snap(tester, 'dojo');
  });

  testWidgets(
    'A pending chat survives restart and retries without duplicating the user message',
    (tester) async {
      final c = await state.newChat();
      c.messages.add(const Message('user', 'Message interrompu'));
      await state.persist();
      await start(tester);
      await tap(
        tester,
        find.widgetWithText(NavigationDestination, 'Clash Chat'),
      );
      expect(find.textContaining('Le dernier message attend'), findsOneWidget);
      await tap(tester, find.text('Réessayer'));
      expect(state.chats.single.messages.length, 2);
      expect(state.chats.single.messages.last.role, 'assistant');
      expect(
        (requests.last.data['messages'] as List)
            .where((m) => m['role'] == 'user')
            .length,
        1,
      );
    },
  );

  testWidgets(
    'Provider editor loads models, tests and stores credentials securely',
    (tester) async {
      await start(tester);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Réglages'));
      await tap(tester, find.text('Modifier / Tester').first);
      await tap(tester, find.text('Récupérer les modèles'));
      expect(find.textContaining('1 modèles récupérés'), findsOneWidget);
      await tap(tester, find.text('Tester la connexion'));
      expect(
        find.text('Connexion réussie : le modèle a répondu.'),
        findsOneWidget,
      );
      await snap(tester, 'provider');
      await tap(tester, find.text('Enregistrer'));
      expect(await state.secrets.read('openai'), 'fixture-key');
      expect(state.store.load().toString(), isNot(contains('fixture-key')));
    },
  );
}
