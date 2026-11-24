# Majlis in WellMate

Majlis (مجلس) is a place to sit together and talk by voice, like a small
Clubhouse. People join under a veil name and a painted portrait: no real
names, no photos, nothing recorded. Every signed-in WellMate user can use it.

## Where it shows up

| Place | What it does |
|---|---|
| Middle tab | The Majlis hallway. The tea-glass icon gets a gold dot when someone is talking. |
| Home, under "How do you feel" | One card: the live space with Join, or the next scheduled space, or the Majlis promise. |
| Home feeling sheet | Tired, anxious or sad: "Sit with others in Majlis" under the usual activity. |
| After a visit | 5 minutes in a space (or 2 minutes speaking or hosting) is the day's journey step. Home replays the step when you go back. |
| After a visit, feeling low | The same activity Home suggests for that feeling (breathing, body scan, mood check). |
| Help in a space | "Talk to WellMate" opens the AI chat. |
| Scheduled spaces | "Remind me" uses WellMate's notifications, 10 minutes before. |

Tabs are now: 0 Home, 1 Games, 2 Majlis, 3 Daily activities, 4 Profile.

## Code

- `lib/features/majlis/`: the feature (hallway, room, sheets, strings in
  English, Dari and Pashto in `l10n/majlis_strings.dart`). Built and tested
  on its own first, in `Learnistan/wellmate-majlis-demo`.
- `lib/features/majlis_glue/`: how WellMate plugs it in (`MajlisScope`, Home
  card, nav icon, reminders, local backend switch).
- `functions/majlis.js`: Cloud Functions (accounts, spaces, voice tokens,
  moderation). `functions/index.js` loads it.
- `firestore.rules`, `firestore.indexes.json`: rules for **all** of WellMate's
  Firestore (the `users/{uid}` sync data and Majlis). Deploying them replaces
  the rules in the console, so keep every feature's rules in this file.
- Voice runs on LiveKit Cloud. Firestore only holds lists and settings.
- Regions: Firestore is in `asia-south2` (Delhi), so the Majlis functions run
  there too (`REGION` in `functions/majlis.js`, `functionsRegion` in
  `firebase_majlis_repository.dart`). The account-deletion trigger is 1st gen,
  which Delhi doesn't offer, so it runs in `us-central1`. The AI chat stays in
  `us-central1`.

## Backend setup (one time, for wellmate-56205)

1. LiveKit Cloud: create a project, then Settings → Keys. Note the URL
   (`wss://….livekit.cloud`), API key and API secret.
2. Secrets (the secret never goes in git or chat):
   ```bash
   firebase functions:secrets:set LIVEKIT_API_KEY --project wellmate-56205
   firebase functions:secrets:set LIVEKIT_API_SECRET --project wellmate-56205
   ```
3. `functions/.env.wellmate-56205` (not secret, already in the repo):
   ```
   LIVEKIT_URL=wss://YOUR-PROJECT.livekit.cloud
   MAJLIS_REQUIRE_VERIFIED_EMAIL=true
   MAJLIS_ENFORCE_APP_CHECK=false
   ```
4. Deploy rules and indexes, then only the Majlis functions (leaves
   `chatWithOpenAI` alone):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes --project wellmate-56205
   firebase deploy --project wellmate-56205 --only functions:majlisCreateSpace,functions:majlisJoin,functions:majlisStage,functions:majlisHost,functions:majlisWhisper,functions:majlisTea,functions:majlisRemind,functions:majlisReport,functions:majlisWebhook,functions:majlisSweep,functions:majlisOnUserDeleted
   ```
5. **Open the public functions.** The Learnistan Workspace blocks granting
   access to "allUsers", so the deploy says "Unable to set the invoker" for
   new callable/HTTP functions. Do what `chatWithOpenAI` already has: turn off
   the Cloud Run invoker check (the functions still check the WellMate
   sign-in, and the webhook checks LiveKit's signature):
   ```bash
   gcloud run services update majlisjoin --region asia-south2 --no-invoker-iam-check --project wellmate-56205
   ```
   (one per function: majliscreatespace, majlisjoin, majlisstage, majlishost,
   majliswhisper, majlistea, majlisremind, majlisreport, majliswebhook).
   Only needed when a function is first created; later deploys keep it.
6. **Service account.** The Workspace also gives Google's default service
   accounts no roles, so Majlis runs as its own account
   `majlis-functions@wellmate-56205.iam.gserviceaccount.com` with only
   `roles/datastore.user` (the deploy adds access to the two LiveKit secrets).
   The public AI chat keeps no database access.
7. LiveKit Cloud → Settings → Webhooks: add
   `https://asia-south2-wellmate-56205.cloudfunctions.net/majlisWebhook`.

**Status (25 Nov 2026):** steps 1–6 done for wellmate-56205 (rules, indexes,
11 functions, cleanup policy for old build images in asia-south2).

Guides: add `majlis_guides/<uid>` with `{ "name": "Nargis" }` in the console.
They can mute, move, remove (never the host), pin and end in any space.
Reports land in `majlis_reports`.

## Running it locally (no real data)

The test repo `Learnistan/wellmate-majlis-demo` has a local backend
(LiveKit + Firebase emulators, project `demo-wellmate`) and a scripted
second person:

```bash
cd ../wellmate-majlis-demo && tool/dev.sh
flutter run --profile --dart-define=WELLMATE_LOCAL_BACKEND=10.0.2.2
```

With `WELLMATE_LOCAL_BACKEND` set, the whole app (sign-in too) uses the
local emulators. It needs a profile build (Firebase then starts from Dart, see
`android/app/src/profile/AndroidManifest.xml`). Store builds never set it.

## Before release

- Android: Play Console must list the media-playback foreground service
  ("keeps a live audio space playing while the screen is off").
- iOS: `pod install`; microphone text and background audio are in Info.plist.
- Two real phones on different networks, a screen-off test, an iPhone test.
- A native speaker reads the Dari and Pashto (list at the top of the strings file).
