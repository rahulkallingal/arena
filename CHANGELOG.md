# 📝 Changelog - Arena

All notable changes to Arena will be documented in this file.

## [1.9.0] - July 12, 2026

### ✨ Added
- **Emoji avatars (profile pictures)** — users now pick an avatar from a set of
  24 emoji (drawn on coloured circles, no image files / storage cost). Choose one
  at **sign-up**, and change it anytime from **Profile & avatar** in the account
  menu. Avatars appear next to the sender's name on every message.
  - Stored on the profile (Firebase Auth `photoURL` + `users/{uid}.avatar`) and
    **denormalized** onto each message (`senderAvatar`) so the chat renders with
    no extra reads — same pattern as `senderName`.
  - If a user hasn't picked one, their avatar falls back to the first letter of
    their name on a colour derived from it.
  - New reusable pieces: `data/avatars.dart`, `widgets/user_avatar.dart`,
    `widgets/avatar_picker.dart`, `screens/profile_screen.dart`.

## [1.8.0] - July 12, 2026

### ✨ Added
- **Admin broadcast topic (Postman API)** — a new HTTP Cloud Function,
  `broadcastTopic`, lets the admin push a brand-new debate to **every user at
  once** by POSTing a single sentence from Postman (or any HTTP client). It
  creates a fresh public room for that sentence and sends one notification to
  the app-wide `all_users` topic. Guarded by a shared secret (`x-arena-key`
  header) so only the admin can fire it. New **"New debates"** notification
  channel (`broadcast`).
- **Tap-to-open a room from a notification** — tapping any push now opens the
  room it points at, in all app states: launched from cold start
  (`getInitialMessage`), from the background (`onMessageOpenedApp`), and from a
  foreground notification (payload-carried roomId). Previously taps did nothing.
  This also improves the existing reply/trending/room-message pushes.
- Every device now subscribes to the `all_users` topic at startup
  (`RoomNotifyService.subscribeAll`) so broadcasts reach everyone.

### ⚠️ Requires (one-time)
- **Set the broadcast secret** (`firebase functions:secrets:set BROADCAST_SECRET`
  — kept in Secret Manager, never in this public repo), **redeploy the Cloud
  Function** (`firebase deploy --only functions`) to publish the new
  `broadcastTopic` endpoint, and rebuild the app so phones subscribe to
  `all_users` and handle notification taps. See `NOTIFICATIONS_SETUP.md` →
  "Admin broadcast topic (Postman)".

## [1.7.0] - July 5, 2026

### ✨ Added
- **Trending-debate notifications** — when a debate you took part in suddenly
  heats up (a burst of ~20+ messages within 30 min), everyone who joined that
  room gets a catchy "🔥 your debate is on fire — jump back in!" push to pull
  them back, even without the 🔔 bell. Powered by the Cloud Function with a
  3-hour per-room cooldown; new **"Trending debates"** notification channel;
  suppressed while you're already in that room. Each device follows a
  `room_participants_<roomId>` topic when it opens a room.
- **Admin "push trending topic"** — signed in as the admin
  (`cryptork97@gmail.com`), the rooms list shows a box to type a topic + a "use
  default push time (9 AM)" toggle (or pick a custom time) + Push. It queues that
  topic to **override the next daily topic** for everyone (stored at
  `config/dailyOverride`); each phone reads it and swaps that day's push. No
  admin topic set → the usual hardcoded topic is used.

### ⚠️ Requires (one-time on Windows)
- **Redeploy the Cloud Function** (`firebase deploy --only functions`) for the
  trending push, and **publish the updated `firestore.rules`** (adds the
  `config/*` rule) in the Firebase console. See `NOTIFICATIONS_SETUP.md`.

## [1.6.0] - July 4, 2026

### ✨ Added
- **Reply notifications** — when someone **replies to your message** in a room,
  you get a notification ("<name> replied to you"), even when the app is closed
  and **even if you don't follow that room**. Delivered by the same Cloud
  Function, targeted to you personally.
  - How it works: each signed-in device subscribes to a personal push topic
    (`user_<uid>`); reply messages now store the quoted author's uid
    (`replyToSenderId`); the Cloud Function pushes to that user's topic on a
    reply. A new **"Replies to you"** notification channel keeps them separate
    from room-follow alerts. You never get notified for replying to yourself.
  - ⚠️ **Requires a redeploy** of the Cloud Function (`firebase deploy --only
    functions`) and a rebuilt app — see `NOTIFICATIONS_SETUP.md` → "Updating".

## [1.5.0] - July 3, 2026

### ✨ Added
- **Forgot password** — a "Forgot password?" link on the login screen emails a
  reset link.
- **Change password** in-app — the account menu (top-right) has "Change
  password" for email/password accounts (re-authenticates, then updates).
- **Chat colour-coding by side** — For (support) messages are **green**, Against
  (oppose) are **red**, for everyone, so sides are visible at a glance.
- **Message pagination** — chat loads only the latest ~30 messages plus a "Load
  earlier messages" button, keeping Firestore reads (and cost) low in busy rooms.
- **(Dev only) Admin quick-login** — a one-tap login button that appears ONLY in
  builds made with `--dart-define ADMIN_EMAIL/ADMIN_PASSWORD`. Public builds omit
  the defines, so it's never shipped and no credentials are compiled in.

### ✨ Improved
- **Login layout** — "Continue with Google" now sits above the Create-account
  button (not after it); the Terms checkbox is above both and shows only on
  signup.
- **Password show/hide** eye on the password field.
- **Auth error messages show in full** (no longer cut off after one line).
- **Verify-email banner clears automatically** once the email is verified (the
  home screen re-checks on resume).
- **"Check your spam/junk folder"** added to the verification + reset messages.
- **After logout you land on the Login view** (not Create account).
- **The two auth buttons load independently** — tapping Create/Log-in no longer
  also spins the Google button, and vice-versa.

### 🐞 Fixed
- **"Just watching" bar** was rendering as vertical text — rebuilt as a robust
  full-width bar.
- **Email/password login hang** — sign-in would spin forever. Cause: builds used
  a stale `google-services.json` after a signing fingerprint was added. Fixed by
  re-pulling the live config (`firebase apps:sdkconfig`) and rebuilding. Google
  sign-in works once the app's SHA-1/SHA-256 are registered in Firebase.

### 🚀 Ops
- Per-room notifications are **deployed and live** (Cloud Function
  `notifyRoomOnNewMessage`, region asia-south1) on the **Blaze** plan (free at
  current scale; a cleanup policy keeps container storage from accruing cost).

## [1.4.0] - July 1, 2026

### ✨ Added
- **Per-room notifications (🔔).** Each debate room now has a bell in its top
  bar (default OFF). Turn it on to get a notification for every new message in
  that room — even when the app is closed. Delivery is powered by a new Firebase
  Cloud Function (`functions/`) that pushes to everyone subscribed to the room's
  FCM topic. Requires a one-time deploy on the Blaze plan — see
  `NOTIFICATIONS_SETUP.md`.

### ✨ Improved
- **Terms & Conditions are only required when creating an account**, not when
  logging in (email or Google).
- **"Just watching" users can no longer type.** The message box is replaced by a
  "Pick a side to join in" prompt until they choose For or Against.
- **Swipe a message left or right to reply** to it (long-press still opens the
  full reply / react / report / block menu).

## [1.3.0] - June 29, 2026

### ✨ Added
- **Remove a room from your own list without deleting it.** Long-press a room
  in **My Rooms** → "Remove from my list" — it disappears from your list but
  the room keeps existing so anyone still chatting there is unaffected. Long-
  press in **Visited** to remove it from your history. Both have an Undo.

### 🔐 Fixed
- **Terms & Conditions are now enforced for Google sign-in too** — the
  "Continue with Google" button stays disabled until the agreement box is
  ticked (matches Create account).

## [1.2.0] - June 29, 2026

### ✨ Improved
- **Your side is remembered per room.** You're asked which side you're on only
  the **first** time you enter a room. After that it defaults to the side you
  chose. You can switch sides anytime with the **⇄ (For/Against/Watching)**
  button in the room's top bar — your new choice is remembered too.
- **Logout now asks for confirmation** ("Log out? Cancel / Log out") so you
  don't get signed out by an accidental tap.
- **Auto-capitalised first letter** on name fields (display name, room name)
  and the debate topic, so entries start with a capital by default. Email and
  password are left untouched.

## [1.1.0] - June 29, 2026

### 🐞 Fixed
- **Your side is now locked once you enter a room.** Before, the For/Against
  chips in the message bar could still be tapped to switch sides mid-debate.
  Now the side you pick when joining is shown as a read-only badge (🔒 Arguing:
  For / Against / Just watching) and can't be changed.
- **Rooms joined by code/link now appear under "Visited."** Entering a room via
  Join by Code now also asks your side and records the room in your history,
  just like every other way of opening a room.

## [1.0.9] - June 29, 2026

### ✨ Improved
- **Topics rewritten in plain, simple words** so anyone can understand and join
  in, whatever their reading level (e.g. "Should there be term limits for
  judges?" → "Should judges be made to leave their job after some years,
  instead of staying for life?"). Still 365, one per day for a full year.
- **"Visited" rooms history:** the home toggle's "Joined" tab is now **Visited**
  and records *every* room you open — including the daily Topic of the Day —
  most recent first, kept separate from the rooms you created ("My Rooms"). So
  you have a real history of rooms you've been in.

## [1.0.8] - June 29, 2026

### ✨ Added
- **365 daily debate topics** (up from ~44): a full year of provocative,
  reply-tempting questions — dilemmas, paradoxes and classic debates across
  Science, Religion/Philosophy, Movies, Politics, Sports, Technology, History
  and "Other" (ethics dilemmas + harmless conspiracy prompts). Topics now go a
  whole year before any repeat. Still chosen deterministically from the date,
  so every phone shows the same topic each day with no server.

## [1.0.7] - June 29, 2026

### ✨ Added
- **Terms & Conditions agreement:** account creation now requires ticking an
  "I agree to the Terms of Service and Privacy Policy" checkbox. **Create
  account** and **Continue with Google** stay disabled until it's checked.
- New in-app **Terms of Service** and **Privacy Policy** pages (tappable links
  on the checkbox). Verified on device: links open the legal pages, ticking the
  box enables the buttons.

## [1.0.6] - June 29, 2026

### ✨ Added
- **Continue with Google** sign-in (real Google account → Firebase), alongside
  email/password.

## [1.0.5] - June 29, 2026

### ✨ Added
- **Reply to a message:** long-press any message → Reply. A quoted preview of
  the original (sender + text) sits above your input while composing and is
  shown at the top of the sent message, so rebuttals are easy to follow.

## [1.0.4] - June 29, 2026

### ✨ Added / improved
- **Login error validation:** wrong/invalid email now highlights the **email**
  field ("Incorrect email address."), wrong password highlights the
  **password** field ("Incorrect password.") — instead of always blaming the
  password.
- **Pick your side before joining:** tapping a room now prompts Support / Oppose
  (or "just watching") and drops you in with that stance preselected.
- **Private group clarity:** private rooms show a clear notice on the card
  ("you'll need the group password — contact the admin") before you tap in.
- **Joined rooms:** new **My Rooms / Joined** toggle on the home screen; rooms
  you join are remembered so you can jump back in.
- **Message reactions:** react to messages with 👍 ❤️ 😂 👏 🔥, with live
  per-emoji counts; add/change/remove updates in real time.
- **Email verification:** sign-up now sends a verification link, with a
  "verify your email" banner + Resend on the home screen.

### 🔐 Firestore rules
- Messages may now be updated **only** to change the `reactions` map (text is
  still immutable). **Re-publish `firestore.rules`** for reactions to work.

## [1.0.3] - June 29, 2026

### 🐞 Fixed
- **Share Room dialog** showed empty Room ID and Share Link fields (and the
  Copy buttons were missing). Rebuilt the value rows as a full-width Column
  with `SelectableText` + a Copy button below each, so the room ID and link
  always render. Verified on device.
- `firestore.rules`: added owner-only access to `users/{uid}/**` so PetBloom
  (same Firebase project) can store per-user data without affecting Arena.

## [1.0.2] - June 28, 2026

### ✨ Fixed
- **Room Filtering Logic**
  - Home screen: Now shows ONLY rooms created by current user
  - Discovery: Shows rooms created by OTHERS only
  - Users no longer see duplicate rooms in both screens
- **Empty State Messages**
  - Updated to reflect new filtering logic
  - Clearer instructions for users

### 📦 Updated
- room_service.dart: Added `watchMyRooms()` method
- rooms_list_screen.dart: Uses user-specific room stream
- room_discovery_screen.dart: Filters out user's own rooms

---

## [1.0.1] - June 28, 2026

### ✨ Added
- **Room Discovery Screen**
  - Browse all public rooms from other users
  - Real-time room list with search
  - Category filtering
  - Trending rooms (active in last 24 hours)

- **Room Sharing System**
  - Unique Room ID generation (format: `debate-abc123`)
  - Shareable deep links: `https://arena.app/room/{roomId}`
  - Copy-to-clipboard for both ID and link
  - Share buttons for WhatsApp, Email, More

- **Join by Code**
  - Paste room ID to join
  - Paste full link to extract and join
  - Auto-detects link format
  - Error handling for invalid codes

- **Deep Linking Support**
  - `arena.app/room/{roomId}` opens app directly
  - Falls back to Play Store if app not installed
  - Automatic room joining on successful open

### 🎨 UI/UX
- New Discover button (search icon) in AppBar
- Room discovery screen with category filter
- Join by code screen with paste functionality
- Share dialog with multiple share options
- Color-coded room categories

### 📦 Created
- room_discovery_screen.dart: Room browsing & search
- room_share_dialog.dart: Room sharing with ID & link
- join_by_code_screen.dart: Code-based room joining

---

## [1.0.0] - June 28, 2026

### ✨ Initial Release

**Core Features**
- User authentication (name sign-in)
- Live debate rooms (public & private)
- Real-time chat with Firestore
- For/Against stance selection
- Topic of the Day feature
- Category organization
- User blocking (local via shared_preferences)
- Message moderation & deletion
- Report functionality
- Daily 9 AM notifications
- Search & category filters

**Technical**
- Flutter 3.44.4
- Firebase (Firestore, Auth, Cloud Messaging)
- flutter_local_notifications for system alerts
- timezone support for scheduling
- Dart 3.12.2

## 🔜 Upcoming Features

### [1.1.0] - Planned
- Google & phone number authentication
- Server-side push notifications via Firebase Cloud Messaging
- Admin panel for managing reported content
- Enhanced user profiles
- User reputation/rating system
- Advanced room analytics

### [2.0.0] - Future
- Audio debate rooms
- Video debate streaming
- Live debate scheduling
- AI-powered moderation
- Community leaderboards
- Debate analytics & insights
- Debate tournament system

---

## 📊 Version History Summary

| Version | Date | Highlights |
|---------|------|-----------|
| 1.0.2 | Jun 28, 2026 | Fixed room filtering (home vs discovery) |
| 1.0.1 | Jun 28, 2026 | Added room discovery, sharing, deep linking |
| 1.0.0 | Jun 28, 2026 | Initial release with core debate features |

---

**Note**: This changelog tracks major changes. See git commit history for detailed technical changes.
