# Eddembe mobile app (Flutter)

The Android app for Eddembe, the legal rights assistant for Uganda. It is a client of the Eddembe API
(`server/` in [eddembe-legal-assistant](https://github.com/Nuwahereza-eng/eddembe-legal-assistant)).
The law, Gemma 4 and Sunbird all stay on the server, so the app uses exactly the same 373 law sections and
citation checks as the web app, and never holds a Gemini or Sunbird key.

Eddembe gives legal information, not legal advice.

## What it does

| Tab / screen | What happens | API |
|---|---|---|
| Language picker | First launch; change later in Settings | `POST /api/translate` for the app's own words |
| Home | Situation buttons (housing, work, land, information from government, something else) with 2–4 tap questions and an optional note | `POST /api/ask` with `input_language: "eng"` |
| Ask | Type or speak a question; answer with citations, next steps, Listen, follow-ups that keep context | `POST /api/ask` with `history`, `/api/speech/stt`, `/api/speech/tts` |
| Scan | Photo, PDF or Word file plus an optional question; what it is, red flags linked to law sections, what is missing | `POST /api/analyze` |
| Letters | Draft, edit, copy, share, save (Firestore, or on the phone without Firebase) | `POST /api/letter` |
| Get help | Live Google Places "legal aid" results near you (map when enabled), then verified organisations and referral requests | `GET /api/places`, Firestore |
| Community Voice | One optional anonymous question after an answer, totals chart | Firestore (write only), `GET /api/community-voice/totals` |
| My cases | Saved letters and help requests with status | Firestore |

## Run it

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://eddembe-legal-assistant-x3nd.vercel.app
```

`API_BASE_URL` defaults to the live Vercel URL. For a local server on the same Wi-Fi, use your laptop's
address, for example `--dart-define=API_BASE_URL=http://192.168.1.20:4100` (the server's CORS is open).

Release APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=MAPS_ENABLED=true
```

### Firebase (sign-in, letters, referrals, Community Voice)

Firebase project: **`eddembe-legal-ug`** (display name Eddembe), with an Android app
(`com.eddembe.eddembe_mobile`) and a Web app. Their settings are in `lib/firebase_options.dart`, passed to
`Firebase.initializeApp`, so no `google-services.json` or Gradle plugin is needed. These are public client
identifiers; access is controlled by `firestore.rules`. Firestore runs in `africa-south1` (Johannesburg).
Authentication uses **Anonymous** sign-in only (no name, phone or email); the app sends the ID token to the API.

```bash
firebase deploy --only firestore:rules     # .firebaserc points at eddembe-legal-ug
# To regenerate the settings after adding a platform:
flutterfire configure --project=eddembe-legal-ug --platforms=android,web
```

If Firebase cannot start, the app still works: letters are kept on the device, and referrals and
Community Voice are switched off.

On the server, set `FIREBASE_PROJECT_ID=eddembe-legal-ug` (checks the app's tokens) and, on Vercel,
`FIREBASE_SERVICE_ACCOUNT` (reads Community Voice totals). The web app sends no token and is not affected.

Firestore collections:

| Collection | Written by | Fields |
|---|---|---|
| `users/{uid}/letters` | the person | `letter_type`, `title`, `content`, `citations`, `updated_at` |
| `support_organisations` | `npm run import-orgs` (server) only | `name`, `type`, `phone`, `email`, `address`, `district`, `languages`, `situations`, `source_url`, `verified_by`, `verified_on`, `accepts_referrals` |
| `referrals` | the person, after ticking consent | `uid`, `organisation_id`, `organisation_name`, `status` (sent, seen, contacted, closed), `created_at`, and only the shared fields of `situation`, `summary`, `phone` |
| `community_voice` | anyone signed in; nobody can read | `barrier`, `situation`, `district` (if shared), `language`, `date` |

Verified organisations: fill `data/support_organisations_template.csv` in the server repo with
organisations the team has checked (`languages` and `situations` separated by `;`), then
`npm run import-orgs -- file.csv --dry-run` and without `--dry-run`. Until then, Get help shows only
Google search results, labelled as such.

### Google Maps

Nearby results come from **Places API (New)** through the server (`GOOGLE_MAPS_API_KEY`), so that key
never ships in the app. The map itself needs a **Maps SDK for Android** key restricted to this app:
put `MAPS_API_KEY=...` in `android/local.properties` (git-ignored) and build with
`--dart-define=MAPS_ENABLED=true`. Both need billing on the Google Cloud project. Without them, Get help
offers a "Search in Google Maps" link instead.

## Languages

From [Sunbird AI's language list](https://docs.sunbird.ai/languages), checked October 2026, in
`lib/config/languages.dart` (and `server/src/services/languages.ts`). All are translated; the mic shows
only where speech-to-text exists, and Listen only where a Ugandan voice exists.

| Language | Code | Speak a question | Listen to answers |
|---|---|---|---|
| English | `eng` | yes | no |
| Luganda | `lug` | yes | yes |
| Runyankole | `nyn` | yes | yes |
| Acholi | `ach` | yes | yes |
| Ateso | `teo` | yes | yes |
| Swahili | `swa` | yes | no |
| Lugbara | `lgg` | yes | no (no voices yet) |
| Kwamba, Lumasaba, Lusoga, Rukiga, Rukonjo, Ruruuli, Rutooro | `rwm`, `myx`, `xog`, `cgg`, `koo`, `ruc`, `ttj` | yes | no |
| Alur, Aringa, Ik, Jopadhola, Kakwa, Karamojong, Kumam, Kupsabiny, Lango, Lubwisi, Lugungu, Lugwere, Lunyole, Ma'di, Pokot, Runyoro, Samia | `alz`, `luc`, `ikx`, `adh`, `keo`, `kdj`, `kdi`, `kpz`, `laj`, `tlj`, `rub`, `gwr`, `nuj`, `mhi`, `pok`, `nyo`, `lsm` | no | no |

Questions are translated to English for law search and Gemma, and answers back. Law names, section
numbers and quoted law text are never translated. The server's Luganda word fixes apply only to Luganda.

## Google technologies

| Tool | Use |
|---|---|
| Gemma 4 (`gemma-4-26b-a4b-it`) via the Gemini API | Reads documents, answers from retrieved law, links red flags to sections, drafts letters |
| Gemini embeddings (`gemini-embedding-2`) | Law search over the 373 sections |
| Flutter, Material 3 | This app |
| Firebase Authentication (anonymous) | Sign-in; ID token checked by the API |
| Cloud Firestore | Letters, referrals, verified organisations, Community Voice |
| Google Maps Platform (Places API (New), Maps SDK for Android) | Nearby legal aid |
| Cloud Run (optional) | `server/Dockerfile`; same `DATABASE_URL` as the web app |

## Limitations

- Anonymous sign-in: letters and requests are tied to this install. Phone number sign-in is next.
- The app's own words are machine-translated by Sunbird at run time and cached; some may read oddly.
- Letters are drafted in English.
- Document photos are not stored (Cloud Storage was cut for time).
- Referral status changes need the partner dashboard, which is next. Community Voice export to BigQuery
  and a Looker Studio partner view are also next.

## Credit

Some features (situation buttons, guided questions, referrals, Community Voice) were inspired by the
[Sauti-Yo](https://github.com/Grace256c/Sauti-Yo) project. No code, text, images or branding were copied.
