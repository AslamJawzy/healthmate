import 'package:flutter/material.dart';

import '../../../core/utils/app_date_utils.dart';
import '../../../core/utils/period.dart';

/// Holds what the Dashboard is currently showing:
/// which period (Day by default) and which date.
class DashboardViewModel extends ChangeNotifier {
  Period _period = Period.day;
  DateTime _anchorDate = AppDateUtils.today();

  Period get period => _period;
  DateTime get anchorDate => _anchorDate;

  void setPeriod(Period period) {
    if (period == _period) return;
    _period = period;
    _anchorDate = AppDateUtils.today();
    notifyListeners();
  }

  /// Moves back or forward one day / week / month.
  void shift(int direction) {
    final d = _anchorDate;
    switch (_period) {
      case Period.day:
        _anchorDate = DateTime(d.year, d.month, d.day + direction);
        break;
      case Period.week:
        _anchorDate = DateTime(d.year, d.month, d.day + 7 * direction);
        break;
      case Period.month:
        _anchorDate = DateTime(d.year, d.month + direction, 1);
        break;
    }
    notifyListeners();
  }

  /// The user cannot move into the future.
  bool get canGoForward {
    final range = AppDateUtils.rangeFor(_period, _anchorDate);
    return range.end.isBefore(AppDateUtils.today());
  }

  void goToToday() {
    _anchorDate = AppDateUtils.today();
    notifyListeners();
  }
}
