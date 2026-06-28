# Arena 🔥

A mobile app for **debating anything**. Jump into a chat room, pick a side, and
argue it out — about science, religion, movies, sport, whatever. Every day the
app features a provocative **Topic of the Day** and reminds you to come debate.

Part of the "Bloom" family of apps (built the same way as PetBloom).

---

## 📌 For the next Claude session / a new device — START HERE
1. **Read [`ARENA_CONTEXT.md`](ARENA_CONTEXT.md)** — the full project context:
   what's built, the data shapes, the roadmap, and the developer notes (Rahul is
   a non-coder; builds happen on Windows).
2. **To build & run it**, follow [`SETUP_WINDOWS.md`](SETUP_WINDOWS.md) — plain
   numbered steps for Firebase + running on a phone.
3. Then continue from the "Still to do" list in `ARENA_CONTEXT.md`.

## Current status
**Stages 1–4 are code-complete but NOT yet built/run on a phone.**
- ✅ Sign in with a name · live room list · create public/private rooms · join
- ✅ Live chat with For/Against stances
- ✅ Moderation: report, block, delete
- ✅ Topic of the Day (shared daily room) + daily 9 AM local notification
- ✅ Search + category filters
- ⏳ Next: real Google/phone sign-in, server-side push (Cloud Messaging), admin
  view of reports — see `ARENA_CONTEXT.md`.

## Tech
Flutter + Firebase (Firestore, Auth, Messaging). On-device blocking via
shared_preferences; daily notifications via flutter_local_notifications.

## Repo layout
- `lib/` — all the app code (see the folder map in `ARENA_CONTEXT.md`)
- `firestore.rules` — paste into Firebase console → Firestore → Rules
- `SETUP_WINDOWS.md` — how to build it (one-time Firebase setup)
- `TESTING.md` — put it on a phone (wireless or USB) and what to try
- `ARENA_CONTEXT.md` — full context + roadmap (the source of truth)

## Progress log
- **2026-06-28** — Stages 1–4 written (rooms, chat, stances, moderation, daily
  topic + notifications, search/filters). First push to GitHub. Not yet built.
- **2026-06-28** — Added `TESTING.md`. Test phone (TECNO KM9) set up for
  wireless adb; app not yet built/installed (needs Windows + Firebase setup).
