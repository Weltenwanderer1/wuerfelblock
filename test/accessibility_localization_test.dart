import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/l10n/app_localizations.dart';
import 'package:wuerfelblock/widgets/die_widget.dart';
import 'package:wuerfelblock/widgets/poker_die_widget.dart';

void main() {
  testWidgets('English die semantics contain no German fragments', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: Row(
            children: [
              DieWidget(
                key: Key('classic-die'),
                value: 4,
                held: true,
                onTap: null,
                index: 0,
              ),
              PokerDieWidget(key: Key('poker-die'), value: 5, held: true),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(const Key('classic-die'))).label,
      'Die 4, held',
    );
    expect(
      tester.getSemantics(find.byKey(const Key('poker-die'))).label,
      'King, held',
    );
    semantics.dispose();
  });
}
