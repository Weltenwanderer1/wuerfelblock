abstract class SavedGameState {
  bool get isComplete;
  List<dynamic> get players;
  String get gameLabel;
  String get modeLabel;
  String get progressLabel;
  Map<String, dynamic> toJson();
}
