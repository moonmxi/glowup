/// Local configuration for endpoints that developers can adjust without
/// passing launch arguments.
class LocalConfig {
  LocalConfig._();

  /// Base URL for the GlowUp service API. Update this value to match the
  /// environment you are targeting, for example:
  /// - Android emulator: http://10.0.2.2:3000/api
  /// - Desktop / web: http://127.0.0.1:3000/api
  static const String serverBaseUrl = 'http://127.0.0.1:3000/api';
}
