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

## CURRENT STATUS (updated 2026-07-03)

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
