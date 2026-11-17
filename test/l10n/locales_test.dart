import 'package:flaszki/app.dart';
import 'package:flaszki/src/l10n.dart';
import 'package:flaszki/src/ui/dead_end_banner.dart';
import 'package:flaszki_logic/flaszki_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Expected copy per system locale (independent literals, not the ARB).
const _copy = {
  'en': {
    'level': 'Level 1',
    'next': 'NEXT',
    'undo': 'Undo',
    'restart': 'Restart',
    'armed': 'Tap again to restart',
    'settings': 'Settings',
    'patterns': 'Colorblind patterns',
    'sound': 'Sound',
    'credits': 'Credits and licenses',
    'privacy': 'Privacy',
    'version': 'Version',
    'licenses': 'Open-source licenses',
    'solved': 'Solved',
    'deadEnd': 'No way to finish from here',
  },
  'pl': {
    'level': 'Poziom 1',
    'next': 'NASTĘPNY',
    'undo': 'Cofnij',
    'restart': 'Od nowa',
    'armed': 'Stuknij ponownie, aby zacząć od nowa',
    'settings': 'Ustawienia',
    'patterns': 'Wzory dla daltonistów',
    'sound': 'Dźwięk',
    'credits': 'Autorzy i licencje',
    'privacy': 'Prywatność',
    'version': 'Wersja',
    'licenses': 'Licencje open source',
    'solved': 'Rozwiązane',
    'deadEnd': 'Stąd nie da się już ukończyć poziomu',
  },
};

Future<void> _launch(WidgetTester tester, List<Locale> system) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = system;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    FlaszkiApp(
      levelSource: (n) => SynchronousFuture(generate(n)),
      version: '1.2.3+4',
      openUrl: (_) async => true,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  for (final MapEntry(key: code, value: t) in _copy.entries) {
    group('system locale $code', () {
      testWidgets('bar, Goal Queue and Solved follow it', (tester) async {
        await _launch(tester, [Locale(code)]);
        expect(find.text(t['level']!), findsOneWidget);
        expect(find.text(t['next']!), findsOneWidget);
        expect(find.byTooltip(t['undo']!), findsOneWidget);
        expect(find.byTooltip(t['restart']!), findsOneWidget);
        expect(find.byTooltip(t['settings']!), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('restart')));
        await tester.pump();
        expect(find.byTooltip(t['armed']!), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));

        for (final p in generate(1).report.solution!) {
          await tester.tap(find.byKey(ValueKey('flask-${p.from}')));
          await tester.pump();
          await tester.tap(find.byKey(ValueKey('flask-${p.to}')));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text(t['solved']!), findsOneWidget);
      });

      testWidgets('Settings sheet and Credits page follow it', (tester) async {
        await _launch(tester, [Locale(code)]);
        await _tap(tester, find.byKey(const ValueKey('settings')));
        for (final k in ['patterns', 'sound', 'credits', 'privacy']) {
          expect(find.text(t[k]!), findsOneWidget, reason: k);
        }
        expect(find.text(t['version']!), findsOneWidget);
        await _tap(tester, find.text(t['credits']!));
        expect(find.text(t['credits']!), findsOneWidget); // page title
        expect(find.text(t['licenses']!), findsOneWidget);
      });

      testWidgets('Dead End banner follows it', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DeadEndBanner(onUndo: () {}, onRestart: () {}),
            ),
          ),
        );
        expect(find.text(t['deadEnd']!), findsOneWidget);
        expect(find.text(t['undo']!), findsOneWidget);
        expect(find.text(t['restart']!), findsOneWidget);
      });
    });
  }

  testWidgets('Polish region variant (pl_PL) resolves to Polish', (
    tester,
  ) async {
    await _launch(tester, [const Locale('pl', 'PL')]);
    expect(find.text('Poziom 1'), findsOneWidget);
  });

  testWidgets('unsupported system locale falls back to English', (
    tester,
  ) async {
    await _launch(tester, [const Locale('de', 'DE')]);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);
  });
}
