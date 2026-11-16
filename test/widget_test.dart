import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabuclash_ai/main.dart';
import 'package:nabuclash_ai/services/app_state.dart';
import 'package:nabuclash_ai/storage/local_store.dart';

import 'core_test.dart' show MemorySecrets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => 1,
        );
  });
  testWidgets(
    'Navigation, rescue, settings, no-key failure and large text layout',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        LocalStore(await SharedPreferences.getInstance()),
        MemorySecrets(),
      );
      await state.initialize();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: state, child: const NabuApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('NABU'), findsOneWidget);
      await tester.tap(find.text('🆘 Sauve-moi'));
      await tester.pumpAndSettle();
      expect(find.text('Il/elle vient de dire quoi ?'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'Ma voiture est vieille',
      );
      await tester.ensureVisible(find.text('Trouver mes 3 ripostes'));
      await tester.tap(find.text('Trouver mes 3 ripostes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ajoute une clé API'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      for (final name in ['Clash Chat', 'Dojo', 'Favoris', 'Réglages']) {
        await tester.tap(find.widgetWithText(NavigationDestination, name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Fournisseurs IA'), findsOneWidget);
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
