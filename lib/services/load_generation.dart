/// Tracks asynchronous load generations so stale completions cannot overwrite newer state.
class LoadGeneration {
  int _current = 0;

  int begin() => ++_current;

  bool isCurrent(int generation) => generation == _current;
}
