# 📝 Changelog - Arena

All notable changes to Arena will be documented in this file.

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
