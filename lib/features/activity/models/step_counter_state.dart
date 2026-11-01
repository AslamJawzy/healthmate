/// MODEL + LOGIC: turns the phone's step sensor reading into "steps today".
///
/// Android's step counter sensor gives the TOTAL steps since the phone was
/// last restarted, not the steps for today. So we remember:
///  - [date]       the day we are counting for (yyyy-MM-dd)
///  - [baseline]   the sensor value at the start of that day
///  - [carried]    steps already counted today before a phone restart
///  - [lastSensor] the last sensor value we saw
///
/// This class has no Flutter or plugin code, so it is easy to unit test.
class StepCounterState {
  final String date;
  final int baseline;
  final int carried;
  final int lastSensor;

  const StepCounterState({
    required this.date,
    required this.baseline,
    required this.carried,
    required this.lastSensor,
  });

  /// Steps walked today.
  int get todaySteps => carried + (lastSensor - baseline);

  /// Works out the new state after a new sensor reading on [today].
  static StepCounterState update(StepCounterState? previous, int sensor, String today) {
    // First reading ever: start counting from now.
    if (previous == null) {
      return StepCounterState(date: today, baseline: sensor, carried: 0, lastSensor: sensor);
    }

    // The phone was restarted: the sensor went back to (near) zero.
    final rebooted = sensor < previous.lastSensor;

    // A new day has started.
    if (previous.date != today) {
      // Count from the last value we saw, so yesterday's steps are not
      // added to today. After a restart, the sensor started again at 0.
      final start = rebooted ? 0 : previous.lastSensor;
      return StepCounterState(date: today, baseline: start, carried: 0, lastSensor: sensor);
    }

    // Same day, but the phone was restarted: keep what we had counted.
    if (rebooted) {
      return StepCounterState(
        date: today,
        baseline: 0,
        carried: previous.todaySteps,
        lastSensor: sensor,
      );
    }

    // Normal case: same day, sensor kept counting.
    return StepCounterState(
      date: today,
      baseline: previous.baseline,
      carried: previous.carried,
      lastSensor: sensor,
    );
  }
}
