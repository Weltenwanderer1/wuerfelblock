import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/qwixx_models.dart';
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

  test('Qwixx row constants describe colors, order, and closure limits', () {
    expect(QwixxRules.rowColors, QwixxColor.values);
    expect(QwixxRules.diceCount, 6);
    expect(
      QwixxRules.whiteDiceCount + QwixxRules.rowColors.length,
      QwixxRules.diceCount,
    );
    expect(QwixxColor.red.numbers, same(QwixxRules.ascendingRowNumbers));
    expect(QwixxColor.green.numbers, same(QwixxRules.descendingRowNumbers));
    expect(QwixxRules.marksBeforeLock, 5);
    expect(QwixxRules.maximumMisses, 4);
    expect(QwixxRules.rowsToCloseGame, 2);
  });

  test('persistence copy has shared domain-owned names', () {
    expect(PersistenceMessages.saveFailed, 'Speichern fehlgeschlagen');
    expect(
      PersistenceMessages.pendingDigitalDiceSave,
      'Der letzte Würfelstand muss zuerst gespeichert werden.',
    );
  });
}
