/// Route path constants used by the router and in tests.
///
/// Centralised here so paths are never duplicated as string literals.
abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const tasks = '/tasks';
  static const taskDetail = '/tasks/:taskId';
  static const settings = '/settings';

  /// Builds the task detail path for a given [taskId].
  static String taskDetailPath(String taskId) => '/tasks/$taskId';
}
