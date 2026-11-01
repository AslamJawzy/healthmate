/// The time periods the user can choose on the Dashboard and Records screens.
enum Period { day, week, month }

extension PeriodLabel on Period {
  String get label {
    switch (this) {
      case Period.day:
        return 'Day';
      case Period.week:
        return 'Week';
      case Period.month:
        return 'Month';
    }
  }
}
