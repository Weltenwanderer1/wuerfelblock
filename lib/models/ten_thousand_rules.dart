/// Authoritative rule and input limits for 10.000.
abstract final class TenThousandRules {
  static const minimumBankScore = 350;
  static const targetScore = 10000;
  static const targetScoreLabel = '10.000';
  static const minimumPlayers = 2;
  static const maximumPlayers = 8;
  static const diceCount = 6;
  static const scoreIncrement = 50;
  static const minimumDieValue = 1;
  static const maximumDieValue = 6;

  static const initialDice = <int>[1, 1, 1, 1, 1, 1];
  static const initialSelection = <bool>[
    false,
    false,
    false,
    false,
    false,
    false,
  ];
}
