# Testing Arena on a Real Phone (Windows)

How to put Arena on your phone and try it. Do the one-time setup in
`SETUP_WINDOWS.md` first (the app needs Firebase to start).

Test phone on record: **TECNO KM9** (Android 15). Same steps work for any phone.

---

## Option A — Wireless (no cable) ⭐ recommended

The phone has already been switched into WiFi-debugging mode once, so on Windows
you usually just connect — no pairing needed.

1. Make sure the **phone and PC are on the same WiFi**.
2. Open **Command Prompt** and go to the app folder:
   ```
   cd C:\Users\rahul\Documents\arena_app
   ```
3. Connect to the phone (use the phone's current IP — check
   **Settings → Wireless debugging → IP address & Port**, the part before `:`):
   ```
   adb connect 192.168.1.13:5555
   ```
   - If Windows says `'adb' is not recognized`, use the full path:
     ```
     "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" connect 192.168.1.13:5555
     ```
   - If the phone shows an **"Allow wireless debugging?"** popup, tick
     *"Always allow"* and tap **Allow**.
   - If it says *"failed to authenticate"*, just run the same `adb connect`
     command 2–3 more times — it settles and turns into `device`.
4. Check Flutter sees the phone:
   ```
   flutter devices
   ```
   You should see the TECNO KM9 listed.
5. Build + install + launch Arena over WiFi:
   ```
   flutter run
   ```

### If wireless won't connect (after a phone reboot)
Rebooting the phone resets WiFi-debugging mode. Re-enable it with **one** cable
plug-in:
1. Plug in USB, accept the **"Allow USB debugging"** popup (tick always-allow).
2. ```
   adb tcpip 5555
   ```
3. Unplug the cable, then back to **Option A, step 3**.

---

## Option B — USB cable (simplest, always works)

1. Plug the phone into the PC with a USB cable.
2. On the phone, accept **"Allow USB debugging"** (tick *Always allow*).
3. ```
   cd C:\Users\rahul\Documents\arena_app
   flutter run
   ```

---

## What to test once it's running
- Pick a name → you land on the rooms list.
- Tap **Topic of the Day** → type a message → it appears instantly.
- Create a **public** room and a **private** room (with a password); rejoin the
  private one to confirm the password is asked.
- Tag messages **For** / **Against** and check the colours.
- Long-press a message → try **Report**, **Block**, and **Delete my message**.
- Best test: run it on **two phones** (or a phone + an emulator) at once and
  watch a message sent on one appear live on the other. 🔥
- Notifications: after Step 6.5 in setup, you should get a 9 AM "topic of the
  day" alert (to test sooner, ask me to temporarily lower the time).

## Handy commands
```
flutter devices                 # list connected phones
flutter run                     # debug build, hot-reload while testing
flutter run --release           # closer to the real Play Store build
adb devices                     # see what adb is connected to
adb disconnect                  # drop all wireless connections
```
