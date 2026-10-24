// Build settings, passed with --dart-define.

/// Our Eddembe API. Example: --dart-define=API_BASE_URL=https://eddembe-api-xxxx.a.run.app
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://eddembe-legal-assistant-x3nd.vercel.app',
);

/// Shows the Google Map on Get help. Turn on once a Maps SDK for Android key is in
/// android/local.properties (MAPS_API_KEY=...). Without it, nearby results show as a list.
const bool mapsEnabled = bool.fromEnvironment('MAPS_ENABLED');
