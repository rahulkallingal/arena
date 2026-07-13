# Arena App — Full Project Context
> Share this file with Claude at the start of a new conversation by saying:
> "Read this file and use it as full context for our project"

---

## About the Developer
- **Name:** Rahul
- **Coding knowledge:** None — Claude builds everything and guides step by step.
- **OS:** Windows 11 (main dev + builds), Ubuntu laptop (commuting; can edit code
  but CANNOT build/run Flutter — no Flutter/Java/Android SDK there).
- **How to work with Rahul:** plain language, no jargon, small numbered steps,
  explain each command before he runs it.

## CURRENT STATUS (updated 2026-07-13)

> This section is the up-to-date snapshot. The sections further down are older
> background; when they disagree, trust this + `CHANGELOG.md` + `git log`.

**Auth & accounts (Firebase project `arena-a049d`, on the Blaze plan):**
- Email/password + Google sign-in + Terms/Privacy gating (Terms only on signup).
- Forgot-password (login screen) and Change-password (account menu) are in.
- Login layout: Google above Create-account; password show/hide; full error
  text; verify-email banner auto-clears; logout lands on Login view.
- **Google sign-in / login require the build's signing SHA-1 to be registered in
  Firebase AND the current `google-services.json` in the build.** If the config
  is stale after a fingerprint change, email/password login HANGS. Fix:
  `firebase apps:sdkconfig ANDROID 1:958305310400:android:e5d31ab9d8711941107f25
  --project arena-a049d` → save to `android/app/google-services.json` → rebuild.
- This PC's debug keystore SHA-1 `7B:32:35:7A:1D:86:6F:A1:12:4B:D3:63:4D:42:AF:
  B4:4D:B1:92:7C` (SHA-256 `80:AE:6F:…:12:89`) is registered. **Before Play
  Store: make ONE real release keystore, register its SHA-1, use it everywhere.**

**Chat:** live rooms/messages, For(green)/Against(red) colour-coding, swipe-to-
reply, reactions, report/block/delete, per-room 🔔 notifications (Cloud Function
`notifyRoomOnNewMessage` DEPLOYED & live, asia-south1). Messages are **paginated**
(latest ~30 + "Load earlier") to keep Firestore cost low.
- **Reply notifications (v1.6.0, needs redeploy):** when someone replies to your
  message you get a personal "<name> replied to you" push, even if you don't
  follow the room. Each device subscribes to topic `user_<uid>`; replies store
  the quoted author's uid (`replyToSenderId`); the same Cloud Function pushes to
  that user's topic (channel `replies`). Redeploy the function + rebuild to
  activate — see `NOTIFICATIONS_SETUP.md`.
- **Trending-debate push (v1.7.0, needs redeploy):** when a room bursts past ~20
  messages in 30 min, participants (topic `room_participants_<roomId>`, joined on
  room open) get a catchy "on fire, jump back in" push (channel `trending`,
  3-hour per-room cooldown). Detection + send are in `notifyRoomOnNewMessage`.
- **Admin "topic of the day" override (moved to Admin app, v1.10.3):** the
  in-app admin card was **removed** from the rooms list. The override is now set
  from the separate **Admin app**, which calls the secret-guarded `setDailyTopic`
  Cloud Function (writes `config/dailyOverride` {topic, category, date, hour,
  minute, setAt}). Each phone's `scheduleDailyTopics` still READS it and overrides
  that day's push (local-override approach); fallback = hardcoded daily topics.
- **Admin broadcast topic / Postman API (v1.8.0, needs redeploy):** HTTP Cloud
  Function `broadcastTopic` (onRequest, region `asia-south1`, guarded by the
  `BROADCAST_SECRET` / `x-arena-key` header). POST a sentence → it creates a
  fresh public room and pushes one notification to the app-wide `all_users`
  topic (channel `broadcast`), reaching everyone at once. Every device subscribes
  to `all_users` at startup (`RoomNotifyService.subscribeAll`).
- **Tap-to-open room (v1.8.0):** tapping any push now opens its room —
  `getInitialMessage` (cold start), `onMessageOpenedApp` (background), and a
  roomId payload on foreground local notifications, routed via a global
  `navigatorKey`. Applies to all push types.
- **Emoji avatars (v1.9.0):** users pick an avatar from 24 emoji (on coloured
  circles — no image assets). Chosen at sign-up and editable via **Profile &
  avatar** (account menu → `screens/profile_screen.dart`). Stored on the profile
  (Auth `photoURL` + `users/{uid}.avatar`) and denormalized onto each message
  (`senderAvatar`), shown next to the name in chat. Fallback = name initial on a
  derived colour. Pieces: `data/avatars.dart`, `widgets/user_avatar.dart`,
  `widgets/avatar_picker.dart`.
- **"Who won?" voting (v1.10.0):** live For/Against tally per room
  (`widgets/vote_panel.dart`, `rooms/{id}/votes/{uid}` subcollection, one vote
  per user). Shown under the topic banner in the chat screen.
- **Profanity warning (v1.10.0):** `data/profanity.dart` flags vulgar words;
  `chat_room_screen._confirmProfanity` warns before sending. Client-side only.
- **Private-room password server-side (v1.10.1, WIRED):** joining a private room
  by code prompts for the password and verifies via the `verifyRoomPassword`
  callable (salted hash in the unreadable `rooms/{id}/secure/auth` subdoc; new
  rooms store no hash on the readable room doc). Uses the `cloud_functions`
  package. `RoomService.createRoom` writes the secure subdoc;
  `join_by_code_screen._promptAndVerifyPassword` gates entry. Already-joined
  members/creators aren't re-prompted.
- **Infra (v1.10.0):** Cloud Functions on **Node.js 22**; daily
  `cleanupStaleRooms` deletes empty rooms idle 7+ days.
- **Login-first screen (v1.10.4):** auth screen opens on **Log in** by default
  (`startInSignUp=false`), with a "New here? Create an account" toggle.
- **Bug fixes (v1.10.5):** (a) notification tap no longer re-opens a room in
  watcher/neutral mode — `main.dart _openRoom` skips the room you're already in
  and restores your saved stance; (b) opening a message's long-press menu drops
  input focus so the keyboard doesn't pop back up on dismiss.
- **Moderation reports view (v1.10.5):** users can already report a message
  (long-press → Report → `reports` collection via `ModerationService`). New
  `reportedMessages` Cloud Function aggregates by message and returns those with
  **2+ distinct reporters**; viewed in the **Admin app** (Moderation card).
  Reports are private to the admin — purely informational, no external/legal
  action.

## Cloud Functions & admin endpoints (project arena-a049d, region asia-south1)

Deploy from the Arena repo: `firebase deploy --only functions --project arena-a049d`
(needs `firebase login` + `cd functions && npm install` once on a new machine).
The admin secret `BROADCAST_SECRET` lives in Google Secret Manager
(`firebase functions:secrets:set BROADCAST_SECRET`) — NOT in this public repo.
The value is baked into the **private Admin app** (`~/admin`, `lib/config.dart`).

| Function | Type | Purpose |
|---|---|---|
| `notifyRoomOnNewMessage` | Firestore trigger | room/reply/trending pushes |
| `broadcastTopic` | HTTP (secret) | push a topic to everyone + make a room |
| `setDailyTopic` | HTTP (secret) | set `config/dailyOverride` topic-of-the-day |
| `deleteRoom` | HTTP (secret) | delete one room by id (+ messages) |
| `clearAllRooms` | HTTP (secret) | wipe ALL rooms (`confirm:"DELETE ALL ROOMS"`) |
| `reportedMessages` | HTTP (secret) | messages with 2+ distinct reporters |
| `verifyRoomPassword` | Callable (auth) | server-side private-room password check |
| `cleanupStaleRooms` | Scheduled (daily) | delete empty rooms idle 7+ days |

Base URL: `https://asia-south1-arena-a049d.cloudfunctions.net/<name>`. HTTP admin
functions take header `x-arena-key: <BROADCAST_SECRET>`. See `NOTIFICATIONS_SETUP.md`.

## Admin app (separate PRIVATE repo)

`~/admin` — Flutter control panel, GitHub `git@github.com:rahulkallingal/admin.git`
(**private**), no login (personal use). Lists apps; the **Arena** module turns the
admin endpoints into on-phone buttons: Send broadcast, Topic of the day,
Moderation (reported messages), Delete a room, Clear all rooms. The `x-arena-key`
secret is pre-filled in `lib/config.dart` (editable in Settings). **Keep this repo
and its APK PRIVATE** — never on the public Drive folder / GitHub releases.

## Release / Google Play — PENDING (not done yet)
- **Package name chosen: `com.cryptork.arena`** (`com.arena.arena` was taken on
  Play). Requires: change `applicationId` in `android/app/build.gradle.kts` +
  register a NEW Android app for it in Firebase (`firebase apps:create android`) +
  swap in the new `google-services.json` + add the **release key SHA-1** (and
  Play App Signing SHA-1) so **Google Sign-In** works on the store build.
- **Signing:** app is currently **debug-signed** (`signingConfigs.getByName("debug")`)
  — Play needs a real **release keystore** and an **`.aab`** (`flutter build appbundle`).
- **Store listing:** 512×512 icon, 1024×500 feature graphic, screenshots,
  short+full description, **privacy policy URL**, content rating + data-safety forms.
- Pricing: choose **Free** (free→paid is not reversible on Play; monetize later via
  IAP/subscriptions/ads).

**Dev admin login:** build with `--dart-define=ADMIN_EMAIL=cryptork97+admin@gmail.com
--dart-define=ADMIN_PASSWORD=9633992347` to get a one-tap "Admin quick login"
button. Public builds omit the defines (button hidden, no creds shipped).

**Builds/distribution:** built on this Windows PC with the debug keystore (so
installs need uninstall-first if a differently-signed copy is present). Latest
APKs live in `C:\Users\rahul\Desktop\Apps\Apks\` and are mirrored to Google Drive
`App APKs` via rclone (`rclone copy <apk> gdrive:"App APKs"`).

**⚠️ Known bug (open):** tapping "Topic of the Day" shows "Could not open today's
room" after the Firestore data was wiped — the daily room isn't re-creating.
Needs a debug build to read the real Firestore error, then a fix.

**Cost note:** Firestore free tier is 50k reads / 20k writes per day — free at a
few users. Chat is read-heavy; pagination (done) keeps it cheap. Realtime
Database is the cheaper option only if Arena reaches thousands of active users.

## What Arena Is
A debate / discussion app. People join **chat rooms** to debate a topic.
- Create a room: **public** or **private (password)**.
- Each room has a **topic/question** to debate (science, religion, movies, etc.).
- **Signature feature (planned):** every day the app auto-creates a room with a
  provocative "topic of the day" and sends a **push notification to everyone**
  to pull them in to debate (the BeReal/Wordle-style daily ritual hook).

## Why this app is different from PetBloom/FuelBloom
PetBloom and FuelBloom are **single-user, phone-only** (shared_preferences, no
server). Arena is **multi-user chat**, so it REQUIRES a backend. We use
**Firebase** (Firestore for live rooms/messages, Firebase Auth for identity,
Cloud Messaging for the daily notification, and later a scheduled Cloud Function
to generate the daily topic).

## Tech Stack
| Part | Tool |
|------|------|
| App framework | Flutter (same version as PetBloom, 3.44.4) |
| Backend / live data | Firebase **Firestore** |
| Sign-in | Firebase **Auth** — Stage 1 uses **Anonymous** (pick a name) |
| Notifications | Firebase **Cloud Messaging** (Stage 3) |
| Daily topic job | Firebase **Cloud Function** on a schedule (Stage 3) |
| Password hashing | `crypto` (SHA-256, client-side for v1) |

## Build Status — Stages 1–4 code-complete (NOT yet run on a device)
| Piece | Stage | Status |
|-------|-------|--------|
| Name screen (anonymous sign-in + display name) | 1 | Done |
| Rooms list (live, newest-activity first) | 1 | Done |
| Create room (name, topic, category, public/private+password) | 1 | Done |
| Join room (private rooms ask for password) | 1 | Done |
| Live chat (stream, auto-scroll, For/Against/neutral stances) | 1 | Done |
| Sign out · Firestore security rules | 1 | Done |
| Report message (→ `reports` collection) | 2 | Done |
| Block user (stored on-device, hides their messages) | 2 | Done |
| Delete own message (long-press menu) | 2 | Done |
| Daily "Topic of the Day" shared room (date-based, no server) | 3 | Done |
| Curated topic pool (`data/daily_topics.dart`, ~45 questions) | 3 | Done |
| Local daily notification at 9 AM with that day's topic | 3 | Done |
| Search rooms · filter by category | 4 | Done |

> All written but NOT built/run on a phone yet — needs the Windows Firebase
> setup in `SETUP_WINDOWS.md`. Notifications need Step 6.5 (Android config) but
> the app runs fine without it; all notification calls are wrapped in try/catch
> so they can never crash the app (the PetBloom release-crash lesson).

### Still to do
- **Stage 3b — server push:** the daily topic currently notifies via an
  on-device scheduled local notification (each phone schedules its own, works
  with no server). To reach users who haven't opened the app recently, add a
  Firebase **Cloud Messaging** send from a scheduled **Cloud Function** (needs
  the Blaze plan — has a free quota). Not built yet.
- **Real sign-in:** replace Anonymous auth with Google / phone OTP.
- **Admin/moderation view:** a screen (or just the Firebase console) to review
  the `reports` collection; later auto-hide heavily-reported messages.

## Folder Structure
```
arena/                       (drop lib/ + pubspec.yaml into a fresh `flutter create`)
  pubspec.yaml               base deps; Firebase added via `flutter pub add` in setup
  firestore.rules            paste into Firebase console → Firestore → Rules
  SETUP_WINDOWS.md           step-by-step build guide for Rahul (Windows)
  ARENA_CONTEXT.md           this file
  lib/
    main.dart                Firebase init + routes (name screen vs rooms list)
    theme.dart               AppColors (arena red/navy), categories, emojis
    models/
      room.dart              Room (+ Firestore (de)serialization)
      message.dart           Message + Stance enum (neutral/forSide/againstSide)
    services/
      auth_service.dart      anonymous sign-in + display name
      room_service.dart      watch/create rooms, watch/send messages, password hash
    screens/
      name_screen.dart       pick a name, enter
      rooms_list_screen.dart live room list + password prompt for private
      create_room_screen.dart create-room form
      chat_room_screen.dart  the live debate + input bar with stance chips
    widgets/
      room_card.dart         one room in the list
      message_bubble.dart    one chat bubble with For/Against tag
```

## Firestore Data Shape
- `users/{uid}` → `{ displayName }`
- `rooms/{roomId}` → `{ name, topic, category, isPrivate, passwordHash?,
  createdBy, createdByName, isDaily, createdAt, lastActivity }`
- `rooms/{roomId}/messages/{msgId}` → `{ text, senderId, senderName, stance,
  createdAt }`

## Theme (lib/theme.dart)
- Primary: `#E63946` arena red · Secondary: `#1D3557` deep navy
- Accent: `#F4A261` orange · Background: `#FFF5F3`
- For = teal-green `#2A9D8F` · Against = red `#E63946`

## Known v1 simplifications / cleanup before launch
- **Anonymous auth** is a placeholder — replace with Google/phone in Stage 4.
- Private-room password is hashed but **checked on the phone**; a determined
  user could read the hash. Move the check to a Cloud Function / rules later.
- No moderation yet — **do not invite real users until Stage 2 ships**.
- Daily topic + notification (the headline feature) is Stage 3, not built yet.

## Product Notes / Decisions
- The daily provocative topic is the real differentiator — build around it.
- Topics are framed as **"debate this"**, never asserted as fact (avoids looking
  like the app pushes misinformation → app-store risk).
- Keep it warm and a little playful (🔥 / ⚔️), not a sterile forum.
