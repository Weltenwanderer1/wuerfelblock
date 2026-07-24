/// User-facing copy shared by persistence flows across game screens/controllers.
abstract final class PersistenceMessages {
  static const saveFailed = 'Speichern fehlgeschlagen';
  static const pendingDigitalDiceSave =
      'Der letzte Würfelstand muss zuerst gespeichert werden.';
  static const pendingColordiceRollSave =
      'Der letzte Wurf muss zuerst gespeichert werden.';
}
