abstract class PersistentState<T> {
  Future<void> localSave(T state);

  Future<void> localDelete();

  T fromStorage();
}
