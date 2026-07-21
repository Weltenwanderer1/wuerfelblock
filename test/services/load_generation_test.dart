import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/services/load_generation.dart';

void main() {
  test('only the newest asynchronous load generation stays current', () {
    final generations = LoadGeneration();

    final first = generations.begin();
    expect(generations.isCurrent(first), isTrue);

    final second = generations.begin();
    expect(generations.isCurrent(first), isFalse);
    expect(generations.isCurrent(second), isTrue);
  });
}
