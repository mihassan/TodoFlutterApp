/// Task priority levels, ordered from lowest to highest.
enum Priority {
  /// No specific priority set.
  none,

  /// Low priority — can be deferred.
  low,

  /// Medium priority — should be done soon.
  medium,

  /// High priority — needs attention now.
  high,
}
