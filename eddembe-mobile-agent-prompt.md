# Build Prompt: Eddembe Mobile App (Flutter) for the Pre-DevFest Hackathon

You are helping Team TechGenz turn our existing Eddembe web app into a Flutter mobile app for the Pre-DevFest Hackathon 2026. Eddembe is a legal rights assistant for Uganda. It uses Gemma 4 through the Gemini API to read legal documents, answer questions from Ugandan law with section citations, and draft letters. Sunbird AI handles local language speech and translation.

The judges want to see Google technologies used well: Gemma 4, the Gemini API, Firebase, Google Cloud and Flutter. The project supports SDG 16 (targets 16.3 and 16.10).

Read this whole file first. Then read the existing repo. Then show me a short plan before writing code.

## Step 0: Clone and understand the existing repo

```
git clone https://github.com/Nuwahereza-eng/eddembe-legal-assistant.git eddembe
cd eddembe
```

What we already know about the repo (confirm each point in the code before relying on it):

- `server/` is Node.js + Express + TypeScript. Routes: `server/src/routes/ask.ts`, `document.ts`, `letter.ts`, `speech.ts`, `translate.ts`. All Gemma calls go through `server/src/services/gemma.ts`.
- Gemma model: `gemma-4-26b-a4b-it`. Embeddings: `gemini-embedding-2`, 768 dimensions, stored in Postgres with pgvector (373 law sections from 6 laws).
- Citations are checked in `server/src/services/citations.ts`. Keep that logic; never bypass it.
- Languages today are only English and Luganda (`lg`/`en` in `translate.ts`, `lug` for Sunbird).
- The Ask route is single-turn: it does not use earlier questions.
- Hosting today: Vercel (one function, root `server`) with Neon Postgres. API runs locally on port 4100.
- Sample documents for testing are in `samples/` (all marked SAMPLE, made-up names).

Before writing anything:

1. Read the README, `server/`, `web/`, `data/laws/` and `samples/`.
2. List every API endpoint with its exact request and response shape, from the code.
3. Tell me what works today and what is missing before you start.

## Law data: one source only

The mobile app must use exactly the same law sections as our web app. There is one source of law for Eddembe, and both apps share it.

- **The law lives only on the server.** The 373 sections from the 6 laws in `data/laws/` are stored in Postgres with pgvector (Neon today) and searched by `server/src/services/retrieval.ts`. The mobile app gets law only by calling our API (Ask, Scan, Letter and any new endpoint). It must never bundle law text, keep its own copy, or call Gemma directly.
- **Reuse the existing retrieval and checks.** Every new or changed endpoint (multimodal, follow-up context, more languages) must call the same retrieval function, the same Gemma prompts in `server/src/prompts/`, and the same citation checks in `server/src/services/citations.ts`. Include the Employment (Amendment) Act, 2026 rule the server already applies.
- **Same database for both apps.** If you deploy the API to Cloud Run, point it at the same database the web app uses (same `DATABASE_URL`). Do not re-ingest the laws into a new database unless I ask. If we later move to Cloud SQL, use the existing `npm run ingest` script on the same `data/laws/` files and the same embedding model, then check that the section count is still 373 before switching.
- **Citations must match the web app.** For the same question in English, the mobile app and the web app should return the same law names and section numbers. Test this with three questions (one tenant, one employment, one access to information) and show me both results side by side.
- **Situation buttons must use these laws.** Each guided flow builds a question for the existing Ask endpoint. Do not write legal answers into the app. Only offer situation buttons that the 6 laws cover (housing, work, land, information from government). For anything else, show "Something else" and let the server answer, which will point to legal aid when the laws do not cover it.
- **Adding a law later** means adding the file to `data/laws/` and running ingest on the server. Both apps get it automatically, with no app update.

## Tools for you (install before coding)

If you are Claude Code, install the official plugins so you use current Flutter and Firebase APIs instead of guessing:

```bash
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter

claude plugin marketplace add firebase/firebase-tools
claude plugin install firebase@firebase
```

- The Dart and Flutter MCP server needs Dart 3.9 or later.
- Plugin rules do not load automatically. Copy the useful Flutter rules from https://github.com/flutter/agent-plugins/tree/main/rules into the project's `CLAUDE.md`.
- I will run `firebase login` myself and tell you which Firebase project to use. Do not create a new Firebase or Google Cloud project, and do not delete or overwrite data, without asking me.
- If you are not Claude Code, check https://docs.flutter.dev/ai/agent-skills and https://firebase.google.com/docs/ai-assistance/mcp-server for your tool's setup.

## Ground rules

1. **Keep the server as the brain.** The mobile app calls our Node.js API, which uses the same law sections as the web app (see "Law data: one source only"). Never put the Gemini or Sunbird API key in the app.
2. **Change the backend as little as possible** and do not break the web app.
3. **Never invent law text, section numbers, organisations, phone numbers, addresses, API endpoints, package APIs or model IDs.** Check official docs (pub.dev, firebase.google.com, docs.sunbird.ai, ai.google.dev). Put `TODO(verify)` where unsure and tell me.
4. **Legal information, not legal advice.** Show the disclaimer on every answer, every letter, and in Settings.
5. **Hackathon time is short.** Build in the order below and test each step on a real Android phone before moving on.
6. Check each package's current version and setup on pub.dev before adding it.
7. **Inspiration, not copying.** Some features below are inspired by the Sauti-Yo project (github.com/Grace256c/Sauti-Yo). Its licence file is empty, so do not copy any of its code, text, images or branding. Write everything fresh and credit Sauti-Yo as inspiration in the README.

## What the app does

1. **Pick a language once** on first launch. Change it in Settings.
2. **Choose your situation (home screen).** Big buttons for common problems: "My landlord wants me out", "Problem at work", "Land dispute", "I need information from government", "Something else". Each one opens a short guided flow (2 to 4 simple questions with tap answers, plus an optional free text or voice note). The answers become a clear question for the Ask endpoint. Users should not need to know legal words.
3. **Ask:** type or speak a question, see the transcription, get an answer with citations and next steps, hear it read aloud where voice exists. Follow-up questions keep the context of the conversation.
4. **Scan (multimodal mode):** take a photo or pick a document, optionally ask a question by text or voice, get one combined result: what the document is, red flags linked to the law, what is missing, citations. Play it aloud where possible.
5. **Letters:** generate, edit, copy, share and save letters. Saved letters sync with Firebase.
6. **Get help:** after every answer, a "Get help" card shows support options: a Google Map of nearby legal aid offices from live Places results, and a short list of verified organisations from our own Firestore list. The user can send a referral request to a verified organisation.
7. **Community Voice:** after an answer, one optional, anonymous question: "What makes it hardest for people in your community to get help?" with tap answers (cost, distance, fear, not knowing where to go, language, other). Only totals are ever shown, never individual answers.

## Languages (from Sunbird AI docs, checked October 2026)

Sunbird supports different languages for each feature. Confirm codes against https://docs.sunbird.ai/languages.md before shipping.

**Voice output (text-to-speech), Ugandan:** Luganda `lug`, Runyankole `nyn`, Acholi `ach`, Ateso `teo`. Lugbara `lgg` is listed but had no voices yet; enable it only when voices exist.

**Voice input (speech-to-text), Ugandan:** Acholi `ach`, Ateso `teo`, Luganda `lug`, Lugbara `lgg`, Lumasaba `myx`, Lusoga `xog`, Rukiga `cgg`, Rukonjo `koo`, Runyankole `nyn`, Ruruuli `ruc`, Rutooro `ttj`, Kwamba `rwm`, Thur `lth`, plus Swahili `swa` and English `eng`.

**Text translation, Ugandan:** Acholi `ach`, Alur `alz`, Aringa `luc`, Ateso `teo`, Ik `ikx`, Jopadhola `adh`, Kakwa `keo`, Karamojong `kdj`, Kumam `kdi`, Kupsabiny `kpz`, Kwamba `rwm`, Lango `laj`, Lubwisi `tlj`, Luganda `lug`, Lugbara `lgg`, Lugungu `rub`, Lugwere `gwr`, Lumasaba `myx`, Lunyole `nuj`, Lusoga `xog`, Ma'di `mhi`, Pokot `pok`, Rukiga `cgg`, Rukonjo `koo`, Runyankole `nyn`, Runyoro `nyo`, Ruruuli `ruc`, Rutooro `ttj`, Samia `lsm`, plus Swahili `swa` and English `eng`.

Rules:

- One config file, `mobile/lib/config/languages.dart`, with each language's name, code and flags `canTranslate`, `canSpeak`, `canListen`.
- Hide the mic when `canSpeak` is false and show: "Voice input is not yet available in this language. Please type."
- Hide the play button when `canListen` is false. Text always works.
- The server's existing word fixes for Luganda (rewording words Sunbird gets wrong) only apply to Luganda. Do not apply them to other languages.

## Backend changes (minimal)

Add only what is missing after reading the code:

1. **Any Sunbird language on every endpoint.** Today only `lg`/`en` work. Accept any code from the lists above. Translate input to English before retrieval and the result back after. Keep law names, section numbers and quoted law text unchanged.
2. **Follow-up context on Ask.** Accept an optional `history` array (last 3 to 5 question and answer pairs, English). Use it to understand the new question and to improve retrieval, but still answer only from retrieved law sections and still run the citation checks.
3. **One multimodal endpoint** if the current document route cannot take a question and audio together, for example `POST /api/analyze`: multipart with `image` or `file`, optional `question`, optional `audio`, and `language`. Transcribe audio if sent, run the Gemma 4 document reading and the law retrieval in parallel (`Promise.all`), then one Gemma 4 call that combines document, question and law into one JSON result with citations. Reuse the existing prompts and citation checks.
4. **Text-to-speech** for the four voice-output languages, with a clear error for the rest.
5. **Firebase ID token check** with the Firebase Admin SDK for app requests. Keep the web app working and tell me exactly how.
6. **CORS and a public URL** so a real phone can reach the API.

Validate every Gemma 4 JSON response with zod, as the server already does.

## Support organisations (verified only)

- Create a Firestore collection `support_organisations` with fields: `name`, `type` (legal aid, labour, land and housing, government information), `phone`, `email`, `address`, `district`, `languages`, `situations` (which situation buttons it serves), `source_url`, `verified_by`, `verified_on`, `accepts_referrals` (true or false).
- **Do not fill it with organisations from your own knowledge.** Create the collection empty, plus a script `mobile/tool/import_orgs.dart` (or a Node script in `server/scripts/`) that imports a CSV that our team fills with organisations we have checked ourselves. Show "verified on" dates in the app.
- Until the list is filled, the Get help card shows only the live Google Maps / Places results for "legal aid" near the user, labelled as search results, not as verified partners.

## Referrals

- A "Request help" button on a verified organisation with `accepts_referrals: true`.
- The user chooses what to share (situation, short summary, optional phone number) and must tick consent before sending. Nothing is shared without consent.
- Save to Firestore `referrals` with `status` (sent, seen, contacted, closed), `organisation_id`, `created_at`, and only the fields the user agreed to share.
- The user can see their referrals and status on the Letters screen (rename it "My cases" if it fits).
- The partner dashboard for organisations is out of scope today. Mention it in the README as next.

## Community Voice

- Optional, one tap, after an answer. Skippable, never asked twice in one session.
- Save to Firestore `community_voice` with only: `barrier`, `situation`, `district` (only if the user chooses to share it), `language`, `date`. No user ID, no name, no phone number, no free text.
- Firestore security rules: the app can create documents but cannot read them.
- For the demo, show totals in a simple chart. Set up the Firebase export to BigQuery if time allows and connect Looker Studio for a partner view; otherwise describe this in the README as next.

## Google technologies (and what each does)

| Tool | Use in Eddembe |
|---|---|
| Gemma 4 via the Gemini API | Reads documents, answers from retrieved law, combines document and law, drafts letters (built) |
| Gemini embeddings (`gemini-embedding-2`) | Law search (built) |
| Google AI Studio | API key and prompt testing |
| Flutter with Material 3 | The Android app |
| Firebase Authentication | Sign-in. Phone number sign-in if time allows; anonymous sign-in for the demo otherwise. Tell me which |
| Cloud Firestore | Saved letters, referrals, support organisations, Community Voice answers |
| Cloud Storage for Firebase | Document photos, only when the user saves a case |
| Google Maps Platform (Maps SDK for Android, Places API) | Nearby legal aid offices on the Get help card |
| Cloud Run | Host the Node.js API so the phone can reach it (we are on Vercel today) |
| BigQuery and Looker Studio (optional) | Community Voice totals for partners |

Set up Firebase with `flutterfire configure`. Never commit service account keys or secrets.

## Mobile app structure

```
mobile/
  lib/
    main.dart
    app.dart
    theme.dart
    config/
      languages.dart
      situations.dart        # situation buttons and their guided questions
      env.dart               # API base URL from --dart-define
    services/
      api_client.dart        # attaches Firebase ID token
      auth_service.dart
      letters_repository.dart
      referrals_repository.dart
      support_repository.dart
      community_voice_service.dart
      audio_service.dart
    models/
    screens/
      language_picker_screen.dart
      home_situations_screen.dart
      guided_flow_screen.dart
      ask_screen.dart
      scan_screen.dart
      result_screen.dart     # shared by Ask, Scan and guided flow
      get_help_screen.dart   # map plus verified organisations
      referral_screen.dart
      my_cases_screen.dart   # letters and referrals
      letter_editor_screen.dart
      settings_screen.dart
    widgets/
      citation_card.dart
      red_flag_tile.dart
      mic_button.dart
      play_answer_button.dart
      community_voice_card.dart
      disclaimer_footer.dart
```

Suggested packages (check pub.dev first): `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `http`, `image_picker`, `file_picker`, `record`, `just_audio` or `audioplayers`, `google_maps_flutter`, `geolocator`, `share_plus`, `shared_preferences`. Use `provider` or plain `setState`.

## Design

Match the web app and the pitch deck:

- Material 3, primary deep green `#1B5E20`, secondary amber `#F9A825` (highlights and warnings only), error `#B3261E`, background `#F8F9FA`, Roboto
- Bottom navigation: Home (situations), Ask, Scan, My cases
- Citations as clear cards: law name in bold, section number as a chip, short excerpt
- Red flags on light red `#FCE8E6` with a warning icon
- Friendly loading text ("Reading your document...", "Checking the law..."), plain error messages with Try again. Answers can take 10 to 90 seconds, so show progress and never let the screen look frozen.
- Compress photos before upload (about 1600px on the long side). The current host refuses uploads over about 4.5 MB.
- Text at least 14sp, buttons at least 48dp, works on a cheap Android phone.

## Build order

Test each step on a real Android phone before the next. After each step, tell me what works and what to test.

1. **Setup:** install the plugins, clone, report endpoints. Create the Flutter app, theme, navigation, language picker.
2. **Reach the API:** use the live Vercel URL from the README if it works from the phone; deploy to Cloud Run if time allows, connected to the same database. API base URL from `--dart-define=API_BASE_URL=...`. Run the three-question citation check against the web app before moving on.
3. **Ask** with citations, next steps and disclaimer. Then add follow-up context.
4. **Scan (multimodal).**
5. **Situation buttons and guided flow** on the home screen.
6. **Voice:** record, transcribe, show transcription, play answers in the four voice languages.
7. **Letters** and **Firebase** sign-in and saving.
8. **Get help:** Maps and Places results, then the verified organisations list and referrals.
9. **Community Voice** card and totals chart.
10. **More languages** on the backend, using the language config.
11. **Polish and README:** app icon (simple green balance scale, no Google logos), release APK, README "Mobile app" section with Google tools, language table, limitations, and Sauti-Yo credit.

If time runs short, cut in this order: BigQuery and Looker Studio, Cloud Storage, referrals (keep the map), Cloud Run (keep Vercel), more languages beyond Luganda and Runyankole, phone number sign-in. Never cut citations or the disclaimer.

## Demo scenario (must work end to end on the phone)

1. Open the app, pick Luganda.
2. Tap "My landlord wants me out", answer the guided questions, and get an answer citing the Landlord and Tenant Act, 2022, section 38.
3. Scan the sample eviction notice and ask by voice in Luganda whether it is allowed. See the transcription, the linked red flag and play the answer.
4. Ask a follow-up: "What if I already paid this month?" and show it keeps the context.
5. Generate a reply letter and save it to My cases.
6. Open Get help and show legal aid offices on the map.
7. Answer the Community Voice question and show the totals chart.
8. Switch to Runyankole and ask a short question.

## Tell me straight away

- If a Sunbird endpoint rejects a language code.
- If any Google service needs billing turned on or a key I must create (Maps, Places, Cloud Run, BigQuery).
- If something in this prompt conflicts with the existing code.

## When you are unsure

Ask me. I would rather answer a question than debug a wrong guess.
