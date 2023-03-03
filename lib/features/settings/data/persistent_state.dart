abstract class PersistentState<T> {
  Future<bool> localSave(T state);

  Future<bool> localDelete();

  T? fromStorage();
}
