import 'package:flutter/cupertino.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggerViewController extends ChangeNotifier {
  BaseTalkerFilter _filter = BaseTalkerFilter();

  bool _isLogOrderReversed = true;

  BaseTalkerFilter get filter => _filter;

  set filter(BaseTalkerFilter val) {
    _filter = val;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  void updateFilterSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void addFilterType(Type type) {
    _filter = _filter.copyWith(types: [..._filter.types, type]);
    notifyListeners();
  }

  void removeFilterType(Type type) {
    _filter = _filter.copyWith(
      types: _filter.types.where((t) => t != type).toList(),
    );
    notifyListeners();
  }

  void addFilterTitle(String title) {
    _filter = _filter.copyWith(titles: [..._filter.titles, title]);
    notifyListeners();
  }

  void removeFilterTitle(String title) {
    _filter = _filter.copyWith(
      titles: _filter.titles.where((t) => t != title).toList(),
    );
    notifyListeners();
  }

  void update() => notifyListeners();
}
