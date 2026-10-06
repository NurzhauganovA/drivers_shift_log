/// Build-time configuration, passed with `--dart-define`.
abstract final class AppConfig {
  /// Base URL of the shift log API, e.g. `http://localhost:8000`.
  /// When empty the app runs in demo mode with an in-memory backend.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// The driver's UTC offset. Kazakhstan uses UTC+5 all year without DST,
  /// so a fixed offset is enough to show wall-clock times on any device.
  static const driverUtcOffsetMinutes = int.fromEnvironment(
    'DRIVER_UTC_OFFSET_MINUTES',
    defaultValue: 300,
  );

  static bool get isDemo => apiBaseUrl.isEmpty;
}
