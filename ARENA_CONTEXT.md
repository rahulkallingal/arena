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
