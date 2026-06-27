# Arena — Setup Guide (Windows)

Follow these steps **in order**. Each one says what it does and exactly what to
type. Don't worry if a step looks technical — just copy the commands.

You only do steps 1–6 **once**. After that, building the app is just step 7.

---

## What you need first
- Your Windows PC with Flutter already installed (same as PetBloom).
- A Google account (the free one you already use is fine).
- The `arena` folder I built (the `lib` folder, `pubspec.yaml`, and these docs).

---

## Step 1 — Make the blank Flutter project

This creates all the hidden Android/iPhone "wrapper" files Flutter needs.

1. Open **Command Prompt** (press Start, type `cmd`, hit Enter).
2. Go to your Documents folder — type this and press Enter:
   ```
   cd C:\Users\rahul\Documents
   ```
3. Create the project:
   ```
   flutter create --org com.arena arena_app
   ```
   This makes a folder `C:\Users\rahul\Documents\arena_app`.

## Step 2 — Drop in the code I wrote

1. Open `C:\Users\rahul\Documents\arena_app` in File Explorer.
2. From my `arena` folder, **copy my `lib` folder and `pubspec.yaml`** into
   `arena_app`, choosing **"Replace the files in the destination"** when asked.
   (This swaps the blank starter code for the real Arena code.)

## Step 3 — Add the packages

Back in Command Prompt:
```
cd C:\Users\rahul\Documents\arena_app
flutter pub add firebase_core cloud_firestore firebase_auth firebase_messaging crypto shared_preferences flutter_local_notifications timezone
```
This downloads everything the app needs (the online backend, password hashing,
blocking, and the daily notification). It also fills these into `pubspec.yaml`
for you.

## Step 4 — Create your Firebase project (the free server)

1. Go to **https://console.firebase.google.com** and sign in with Google.
2. Click **Add project** → name it `Arena` → keep clicking Continue → **Create
   project** (you can turn Google Analytics OFF, it's not needed).

## Step 5 — Connect the app to Firebase (one magic command)

There's a tool that wires everything up automatically. Run these two commands in
Command Prompt (still inside the `arena_app` folder):

1. Install the tool (only needed once on your PC):
   ```
   dart pub global activate flutterfire_cli
   ```
2. Connect:
   ```
   flutterfire configure
   ```
   - Use the **arrow keys** to highlight your **Arena** project, press Enter.
   - When it asks which platforms, make sure **android** is ticked (press space
     to tick), press Enter.
   - It will think for a bit, then say "Firebase configuration file generated".

   This creates the `lib/firebase_options.dart` file the app expects. ✅

## Step 6 — Turn on the two Firebase features we use

In the Firebase website (console.firebase.google.com, your Arena project):

**A) Sign-in (so people can pick a name):**
1. Left menu → **Build → Authentication** → **Get started**.
2. Open the **Sign-in method** tab → click **Anonymous** → toggle it **On** →
   **Save**.

**B) Database (stores rooms & messages):**
1. Left menu → **Build → Firestore Database** → **Create database**.
2. Choose a location near you → Start in **production mode** → **Create**.
3. Open the **Rules** tab, delete everything there, paste the contents of the
   `firestore.rules` file (in my arena folder), then click **Publish**.
   *(These rules let signed-in people read and post, which is what we want.)*

## Step 6.5 — Switch on the daily-notification support (Android)

The daily "topic of the day" alert needs two small file tweaks. The app still
runs fine without them — you just won't get the daily alert — so if this feels
fiddly, skip it and come back later.

1. Open `android/app/build.gradle.kts` and inside the `android { ... }` block
   add (if not already there):
   ```
   compileOptions {
       isCoreLibraryDesugaringEnabled = true
   }
   ```
   Then inside the `dependencies { ... }` block at the very bottom of that file
   add:
   ```
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   ```
2. Open `android/app/src/main/AndroidManifest.xml` and just below the opening
   `<manifest ...>` line add:
   ```
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```
3. Create a file `android/app/proguard-rules.pro` with this line (prevents the
   release-build crash PetBloom hit):
   ```
   -keep class com.dexterous.** { *; }
   ```

If any of that is confusing, send me a screenshot of the file and I'll tell you
exactly what to paste where.

## Step 7 — Run the app! 🎉

1. Plug your phone in by USB (with USB debugging on, like with PetBloom).
2. In Command Prompt, inside `arena_app`:
   ```
   flutter run
   ```
3. The app opens on your phone. Pick a name → create a room → type a message.
   Open the same app on a second phone (or the emulator) to see messages appear
   live on both. 🔥

To build the installable file later (same as PetBloom):
```
flutter build apk --release
```

---

## If something goes wrong
- **Red error mentioning `firebase_options.dart`** → Step 5 didn't finish. Run
  `flutterfire configure` again.
- **"Missing or insufficient permissions"** → Step 6B rules weren't published.
  Re-paste `firestore.rules` and click Publish.
- **Stuck on the name screen / "Could not sign in"** → Step 6A (Anonymous
  sign-in) is still Off. Turn it On.
- Anything else: copy the red text and send it to me, I'll tell you the fix.

---

## What works right now (Stages 1–4)
- Pick a display name and enter.
- **Topic of the Day** card at the top — tap to join today's shared debate.
- **Search** rooms and **filter by category**.
- Live list of all debate rooms.
- Create a room: name, topic/question, category, public **or** private (with a
  password).
- Join any public room; private rooms ask for the password.
- Live chat inside a room — tag each message **For**, **Against**, or neutral.
- **Long-press any message** to report it, block its author, or delete your own.
- **Daily notification** at 9 AM with today's topic (after Step 6.5).

## Still to come
- Stage 3b: Push the daily topic to people who haven't opened the app recently
  (needs Firebase Cloud Messaging from a server — a later add-on).
- Real **Google / phone sign-in** (right now you just pick a name).
- A simple admin view of reported messages.
