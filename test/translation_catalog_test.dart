import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/l10n/translations.g.dart';

void main() {
  final placeholder = RegExp(r'\$\{[^}]+\}|\$[A-Za-z_]\w*');

  test('generated catalog matches its reviewed offline source', () {
    final source =
        (jsonDecode(File('tool/translations_en.json').readAsStringSync())
                as Map<String, dynamic>)
            .cast<String, String>();

    expect(englishCatalog, source);
    expect(englishCatalog.length, greaterThan(600));
  });

  test('translations preserve placeholders and contain no scanner debris', () {
    for (final entry in englishCatalog.entries) {
      expect(
        placeholder
            .allMatches(entry.value)
            .map((match) => match.group(0))
            .toSet(),
        containsAll(
          placeholder
              .allMatches(entry.key)
              .map((match) => match.group(0))
              .toSet(),
        ),
        reason: entry.key,
      );
      expect(entry.key, isNot(startsWith('../')));
      expect(entry.key, isNot(contains('.dart')));
      expect(entry.key, isNot(contains('child: InkWell')));
      expect(entry.key, isNot(contains('Future<void>')));
    }
  });

  test('known machine-translation failures stay banned', () {
    final english = englishCatalog.values.join('\n').toLowerCase();
    for (final banned in [
      'on the train',
      'digital cubes',
      'trickle',
      'current litter',
      'speed dial',
      'billing based',
      'a quirk',
      'ratings are',
      'regulate',
    ]) {
      expect(english, isNot(contains(banned)), reason: banned);
    }
  });
}
