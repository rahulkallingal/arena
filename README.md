# 🎤 Arena

A dynamic social debating platform where users can create debate rooms, join discussions, and argue different sides on any topic in real-time.

## ✨ Key Features

### 🏠 Core Functionality
- **Live Chat Rooms** - Real-time debates with "For" and "Against" stances
- **Create Public/Private Rooms** - Start your own debate topics
- **Room Discovery** - Browse and search all public debates
- **Smart Sharing** - Share room IDs and links with unique codes
- **Join Methods** - Search, enter code, or click direct links
- **Moderation** - Report, block, and delete inappropriate content
- **Topic of the Day** - Featured daily debate with 9 AM notifications

### 🔍 Discovery & Sharing
- **Room Search** - Find debates by name or topic
- **Category Filtering** - Browse by Politics, Tech, Science, Sports, etc.
- **Trending Rooms** - See active debates from last 24 hours
- **Room Sharing** - Copy Room ID or shareable link to clipboard
- **Deep Linking** - Open room links directly in app or Play Store
- **Join by Code** - Paste room ID or link to instantly join

### 💬 Chat Features
- **Stance Selection** - Choose "For" or "Against" when entering room
- **Real-Time Messages** - Live discussion with other debaters
- **User Blocking** - Block disruptive users locally
- **Message History** - See full conversation in each room

### 🛡️ Moderation Tools
- **Report Content** - Report inappropriate messages or rooms
- **User Blocking** - Block users from your view
- **Message Deletion** - Remove your own messages
- **Room Moderation** - Room creator can moderate discussions

## 📱 User Experience

### Home Screen (Your Rooms)
- View only debates **you created**
- Manage your debate rooms
- Edit or delete rooms anytime
- Search your own debates by category

### Discover Screen (Others' Rooms)
- Browse all public debates created by others
- Search by room name or topic
- Filter by category
- See trending active debates
- Join with one tap

### Room Screen
- Live real-time chat
- Your stance (For/Against) displayed
- Participant list
- Moderation options
- Room sharing button

## 🎯 Current Features (v1.0)

✅ User authentication with name sign-in  
✅ Live debate rooms (public & private)  
✅ For/Against stance selection  
✅ Real-time chat with Firestore  
✅ Category organization (Politics, Tech, Science, Sports, Entertainment, Society, Other)  
✅ Room discovery & search  
✅ Trending rooms  
✅ Room sharing with ID & link  
✅ Join by code  
✅ Deep linking support (arena.app/room/{id})  
✅ Topic of the Day  
✅ Daily 9 AM notifications  
✅ User blocking (local)  
✅ Message moderation  
✅ Report functionality  

## 📦 Installation

### From APK
1. Download `Arena.apk` from [releases](https://github.com/rahulkallingal/arena/releases)
2. Enable installation from unknown sources in Settings
3. Open the APK and install
4. Launch and sign in with a display name

### From Source
```bash
git clone https://github.com/rahulkallingal/arena.git
cd arena
flutter pub get
flutter run
```

## 🚀 Getting Started

1. **Sign In**
   - Enter your display name
   - Tap "Sign in"
   - Ready to debate!

2. **Browse Debates**
   - Tap Discover (search icon) to see rooms created by others
   - Search by name or topic
   - Filter by category
   - Browse trending debates

3. **Join a Debate**
   - **Option A**: Search and tap room
   - **Option B**: Enter room code in "Join by Code"
   - **Option C**: Click shared link
   - Select your stance (For or Against)

4. **Create Your Debate**
   - Tap "New room"
   - Name your debate topic
   - Select category
   - Choose public or private
   - Share the room ID/link with friends

5. **Participate**
   - Type messages in the chat
   - React to other debaters
   - Block disruptive users
   - Report inappropriate content

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.44.4
- **Backend**: Firebase (Firestore, Authentication, Cloud Messaging)
- **Local Storage**: Shared Preferences (for blocking)
- **Notifications**: flutter_local_notifications + timezone
- **Language**: Dart 3.12.2

## 📋 Requirements

- Android 5.0+
- iOS 11.0+ (future)
- Internet connection for live chat
- Display name for sign-in

## 🔐 Privacy & Security

- **Room Privacy**
  - Public rooms: Anyone can join
  - Private rooms: Password protected
  - Room creator controls access

- **Data Security**
  - Firebase Firestore encryption
  - Secure authentication
  - User data privacy

- **Blocking & Moderation**
  - Block users locally on your device
  - Report inappropriate content
  - Room creator moderation tools

## 🌟 Room Sharing Feature

### Share Your Room
1. Tap room → Tap "Share" button
2. See **Room ID**: `debate-abc123xyz`
3. See **Link**: `https://arena.app/room/debate-abc123xyz`
4. **Copy** either to clipboard
5. Share via WhatsApp, Email, Telegram, etc.

### Join via Share
1. Receive Room ID or link from friend
2. Paste in "Join by Code" screen, OR
3. Click the shared link
4. Select your stance
5. Start debating!

## 🔜 Upcoming Features

### v1.1 (Planned)
- Google & phone number authentication
- Server-side push notifications
- Admin panel for reported content
- Enhanced user profiles
- User reputation system

### v2.0 (Future)
- Audio/video debates
- Live debate scheduling
- Debate moderation AI
- Community leaderboards
- Debate analytics

## 🐛 Known Issues

None currently. Please report issues on [GitHub Issues](https://github.com/rahulkallingal/arena/issues).

## 🤝 Contributing

Contributions welcome! Submit a Pull Request or open an issue.

## 📄 License

Private project. All rights reserved.

## 👤 Author

**Rahul Kallingal**
- GitHub: [@rahulkallingal](https://github.com/rahulkallingal)
- Email: rahulkallingal05@gmail.com

## 📚 Documentation

- [`ARENA_CONTEXT.md`](ARENA_CONTEXT.md) - Full project context and architecture
- [`SETUP_WINDOWS.md`](SETUP_WINDOWS.md) - Build and setup instructions
- [`TESTING.md`](TESTING.md) - Testing guide and what to try
- [`CHANGELOG.md`](CHANGELOG.md) - Version history and changes
- [`FEATURES.md`](FEATURES.md) - Detailed feature documentation

---

**Current Version**: v1.0.2  
**Last Updated**: June 28, 2026

Made to spark great debates! 🔥
