import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/models/ten_thousand_rules.dart';
import 'package:wuerfelblock/services/persistence_messages.dart';

void main() {
  test('10.000 exposes one authoritative set of rule and input limits', () {
    expect(TenThousandRules.minimumBankScore, 350);
    expect(TenThousandRules.targetScore, 10000);
    expect(TenThousandRules.diceCount, 6);
    expect(TenThousandRules.scoreIncrement, 50);
    expect(TenThousandGameState.winningScore, TenThousandRules.targetScore);
  });

  test(
    'Colordice row constants describe colors, order, and closure limits',
    () {
      expect(ColordiceRules.rowColors, ColordiceColor.values);
      expect(ColordiceRules.diceCount, 6);
      expect(
        ColordiceRules.whiteDiceCount + ColordiceRules.rowColors.length,
        ColordiceRules.diceCount,
      );
      expect(
        ColordiceColor.red.numbers,
        same(ColordiceRules.ascendingRowNumbers),
      );
      expect(
        ColordiceColor.green.numbers,
        same(ColordiceRules.descendingRowNumbers),
      );
      expect(ColordiceRules.marksBeforeLock, 5);
      expect(ColordiceRules.maximumMisses, 4);
      expect(ColordiceRules.rowsToCloseGame, 2);
    },
  );

  test('persistence copy has shared domain-owned names', () {
    expect(PersistenceMessages.saveFailed, 'Speichern fehlgeschlagen');
    expect(
      PersistenceMessages.pendingDigitalDiceSave,
      'Der letzte Würfelstand muss zuerst gespeichert werden.',
    );
  });
}
