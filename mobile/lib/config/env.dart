// Build settings, passed with --dart-define.

/// Our Eddembe API. Example: --dart-define=API_BASE_URL=https://eddembe-api-xxxx.a.run.app
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://eddembe-legal-assistant-x3nd.vercel.app',
);

/// Shows the Google Map on Get help. Turn on once a Maps SDK for Android key is in
/// android/local.properties (MAPS_API_KEY=...). Without it, nearby results show as a list.
const bool mapsEnabled = bool.fromEnvironment('MAPS_ENABLED');

/// The USSD code for phones without the app (answers come by SMS). The default is the Africa's Talking
/// sandbox code, which works in their simulator only; set the live code when there is one:
/// --dart-define=USSD_CODE=*XXX*YYYY#
const String ussdCode = String.fromEnvironment('USSD_CODE', defaultValue: '*384*21981#');
