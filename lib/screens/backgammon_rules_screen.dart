import 'package:flutter/material.dart';
import '../widgets/backgammon_board.dart';

class BackgammonRulesScreen extends StatelessWidget {
  const BackgammonRulesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sections = <(String, String)>[
      (
        'Ziel und Aufstellung\nBringe alle 15 Steine ins Heimfeld und spiele sie aus. Hell startet auf 24×2, 13×5, 8×3, 6×5; Dunkel auf 1×2, 12×5, 17×3, 19×5.',
        'Goal and setup\nBring all 15 checkers home and bear them off. Light starts on 24×2, 13×5, 8×3, 6×5; dark on 1×2, 12×5, 17×3, 19×5.',
      ),
      (
        'Richtung\nHell: 24 → 1 → Ausspielen. Dunkel: 1 → 24 → Ausspielen. Die globalen Punktnummern bleiben fest. Dunkels eigener Punkt n ist global 25−n.',
        'Direction\nLight: 24 → 1 → bear off. Dark: 1 → 24 → bear off. Global point numbers never change. Dark’s own point n is global 25−n.',
      ),
      (
        'Eröffnung\nJede Person würfelt einmal. Bei Gleichstand erneut würfeln. Der höhere Wert beginnt mit beiden Werten.',
        'Opening\nEach person rolls one die. Roll again on a tie. The higher roller starts using both values.',
      ),
      (
        'Ziehen und Pasch\nJeder Zug verwendet einen einzelnen Würfel, auch bei Zwischenzügen. Nutze so viele Werte wie möglich. Ist nur ein Wert nutzbar, musst du ihn spielen. Wären beide einzeln möglich, aber nicht zusammen, ist der höhere verpflichtend. Pasch erlaubt vier Züge mit demselben Wert.',
        'Moves and doubles\nEach move uses one die, including intermediate steps. Use as many values as possible. If only one value is playable, you must use it. If either is playable alone but not both together, you must use the higher. Doubles give four moves of the same value.',
      ),
      (
        'Schlagen und Bar\nZwei gegnerische Steine sperren einen Punkt. Ein einzelner wird geschlagen. Steine auf der Bar müssen zuerst eingesetzt werden.',
        'Hitting and bar\nTwo opposing checkers block a point. A single opposing checker is hit. Checkers on the bar must re-enter first.',
      ),
      (
        'Ausspielen\nErst wenn alle eigenen Steine im Heimfeld sind. Ein höherer Wurf darf nur ausspielen, wenn kein eigener Stein weiter vom Ausspielen entfernt ist.',
        'Bearing off\nOnly when all your checkers are home. An oversized die may bear off only if no checker is farther from bearing off.',
      ),
      (
        'Sieg\nNormal: 1 Punkt, Gegner hat ausgespielt. Gammon: 2 Punkte, Gegner hat nichts ausgespielt. Backgammon: 3 Punkte, zusätzlich gegnerische Steine auf der Bar oder im Heimfeld des Siegers.',
        'Winning\nNormal: 1 point, opponent has borne off. Gammon: 2 points, opponent has borne off none. Backgammon: 3 points, with opposing checkers also on the bar or in the winner’s home board.',
      ),
      (
        'Echte Würfel und Rücknahme\nBeide Werte ausdrücklich eingeben. Bewegungen im aktuellen Wurf können zurückgenommen werden, nicht der Wurf selbst. Zugende ist ausdrücklich zu bestätigen.',
        'Physical dice and undo\nEnter both values explicitly. Moves within the current roll can be undone, but not the roll itself. Confirm the end of each turn.',
      ),
      (
        'Einzelpartie ohne Verdopplung\nKeine Jacoby-, Crawford-, Beaver- oder automatischen Verdopplungsregeln.',
        'Single game without doubling\nNo Jacoby, Crawford, Beaver or automatic doubling rules.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bgText(context, 'Backgammon · Regeln', 'Backgammon · Rules'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                bgText(context, s.$1, s.$2),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SelectableText(
            'Backgammon Galore\nhttps://www.bkgm.com/rules.html',
          ),
        ],
      ),
    );
  }
}
