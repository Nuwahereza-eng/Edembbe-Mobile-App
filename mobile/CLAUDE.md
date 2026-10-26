# Eddembe mobile app: notes for coding agents

Flutter (Material 3) Android client of the Eddembe API in `~/eddembe/server`. See README.md.

## Ground rules

- The server is the brain. The app gets law only from the API (`/api/ask`, `/api/analyze`, `/api/letter`).
  Never bundle law text, call Gemma or Sunbird directly, or put an API key for them in the app.
- Never invent law text, section numbers, organisations, phone numbers, endpoints, package APIs or model IDs.
  Situation buttons build questions (`lib/config/situations.dart`); they never contain legal answers.
- Show the disclaimer (`DisclaimerFooter`) on every answer, every letter, and in Settings.
- Law names, section numbers and excerpts are shown exactly as the server returns them, never translated.
- Language capabilities live only in `lib/config/languages.dart` (kept in step with
  `server/src/services/languages.ts`). `canSpeak` = speech-to-text (mic), `canListen` = read aloud (play).
- Verified organisations come only from Firestore `support_organisations`, imported by the team.
- Community Voice stores no user ID, name, phone or free text; the app writes but never reads it.
- Text at least 14sp, buttons at least 48dp; it must work on a cheap Android phone.

## Build and check

```bash
export PATH=$HOME/Downloads/flutter/bin:$PATH
flutter analyze && flutter test
flutter build apk --debug
```

The laptop has 8 GB of RAM; `android/gradle.properties` caps Gradle at 2.5 GB so builds are not killed.

## Hot reload (from flutter/agent-plugins rules)

After editing a `.dart` file under `lib/` (not tests, and not comment-only changes), find the running app
with the Dart MCP server (`dtd` / `list_running_apps`) and run `hot_reload` for UI or simple method changes,
or `hot_restart` when `initState`, global or static state, or `main()` changed.
