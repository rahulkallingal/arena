# Room Notifications — One-Time Setup (Windows)

This turns on the **🔔 bell** in each debate room. When someone flips it on, they
get a notification for every new message in that room — even when the app is
closed. Delivery is done by a tiny Firebase "Cloud Function" that lives on
Firebase's servers.

You only do this setup **once**. After that, it just works.

> Plain-language note: a "Cloud Function" is a small piece of code that runs on
> Google's servers. Every time a new message is posted, it wakes up and sends
> the notification to the people who asked for it. The app on the phone can't do
> this by itself when it's closed — that's why we need it.

---

## What's already been built for you

- ✅ The 🔔 toggle in each room (in the app).
- ✅ The phone side (it subscribes/unsubscribes when you tap the bell).
- ✅ The Cloud Function code, in the `functions/` folder.
- ✅ The `firebase.json` config file.

You just need to **turn on billing** and **upload (deploy)** the function.

---

## Step 1 — Turn on the Blaze plan (needed for Cloud Functions)

Cloud Functions require Firebase's **Blaze** ("pay as you go") plan. It has a
large free monthly allowance, so at Arena's current size this will almost
certainly cost **₹0** — but Google requires a card on file.

1. Open <https://console.firebase.google.com> and click your **Arena** project.
2. Bottom-left, click the **⚙️ / plan name** (it currently says *Spark*).
3. Click **Upgrade** → choose **Blaze**.
4. Add a payment method and confirm.
5. (Optional but smart) Set a **budget alert** of, say, ₹100 so you're emailed
   if usage ever grows. Google will *not* auto-charge beyond real usage.

---

## Step 2 — Install Node.js (if you don't have it)

The Firebase tools run on Node.js.

1. Go to <https://nodejs.org> and download the **LTS** version for Windows.
2. Run the installer, click Next through it, Finish.
3. To check it worked, open **Command Prompt** and type:
   ```
   node --version
   ```
   You should see a version number like `v20.x.x`.

---

## Step 3 — Install the Firebase command-line tool

In Command Prompt, type:
```
npm install -g firebase-tools
```
Wait for it to finish (a minute or two).

---

## Step 4 — Log in to Firebase

```
firebase login
```
This opens your browser — sign in with the **same Google account** that owns the
Arena Firebase project, and click **Allow**.

---

## Step 5 — Point the tools at your project

Go to the Arena app folder, then pick your project:
```
cd C:\Users\rahul\Desktop\Apps\arena
firebase use --add
```
Use the arrow keys to select your **Arena** project, press Enter, and when it
asks for an alias, type `default` and press Enter.

---

## Step 6 — Install the function's dependencies

```
cd functions
npm install
cd ..
```

---

## Step 7 — Deploy (upload) the function

```
firebase deploy --only functions
```
This uploads the notification function to Google's servers. The first deploy can
take a couple of minutes and may ask to enable a required API — say **yes**.

When it finishes you'll see **✔ Deploy complete!**

---

## Step 8 — Test it (best with two phones, or a phone + emulator)

1. Rebuild the app onto your phone (`flutter run`, see `TESTING.md`).
2. Open a room on **Phone A** and tap the **🔔 bell** so it turns solid
   (notifications on). Press Home so the app is in the background.
3. On **Phone B** (a different account), open the same room and send a message.
4. **Phone A** should get a notification in its notification bar. 🎉

If you only have one phone: turn the bell on in a room, background the app, and
have a friend (or a second account on the web) post — you'll get the alert.

---

## Good to know

- **Turning the bell off** unsubscribes that phone — no more alerts for that room.
- **Default is OFF** for every room, so nobody is spammed unless they opt in.
- The person **sending** a message won't normally get a notification for their
  own message while they're in the room.
- If a notification doesn't arrive, check: the phone allows notifications for
  Arena, and the app has been rebuilt since these changes.

---

## Admin broadcast topic (Postman) — v1.8.0

Push a **brand-new debate to everyone at once** by sending one sentence from
Postman (or any HTTP tool). It creates a fresh public room for that sentence and
notifies every user; tapping the notification opens that room.

**One-time (same as the other updates):**
1. **Set the secret key** (stored in Google Secret Manager, kept out of this
   public repo):
   ```
   firebase functions:secrets:set BROADCAST_SECRET
   ```
   Paste the key you want when prompted (this is the value you'll send from
   Postman). To change it later, run the same command again and re-deploy.
2. `firebase deploy --only functions` — publishes the new `broadcastTopic`
   endpoint. When it finishes, note the URL it prints, e.g.
   `https://asia-south1-arena-a049d.cloudfunctions.net/broadcastTopic`.
3. Rebuild the app onto every phone (so each device joins the `all_users` topic
   and can open a room when a notification is tapped). Only phones on this build
   (or newer) receive broadcasts.
4. If the first call returns **403 Forbidden**, the gen-2 function needs public
   invocation:
   `gcloud functions add-invoker-policy-binding broadcastTopic --region=asia-south1 --member=allUsers`

**Send a broadcast from Postman:**
- Method: `POST`
- URL: the `broadcastTopic` URL from the deploy
- Header: `x-arena-key: <the BROADCAST_SECRET you set in step 1>`
- Body → raw → JSON: `{ "topic": "Should AI replace teachers?" }`
  (a raw-text body containing just the sentence also works; optional
  `"category"` field)
- Response: `{ "ok": true, "roomId": "...", "topic": "..." }`

**Security:** the endpoint is protected only by the `BROADCAST_SECRET` shared
key (in Google Secret Manager, never in the repo). Keep it private, and rotate
it (`firebase functions:secrets:set BROADCAST_SECRET`, then re-deploy) if it ever
leaks — anyone with the URL + key can push to all users.

---

## Updating — trending-debate + admin "push trending topic" (v1.7.0)

Two more features are in the app but need the same one-time re-deploy:
- **Trending-debate push** — pulls people back when a debate heats up.
- **Admin "push trending topic"** — you (the admin) can override the day's topic.

Do this once (same as the reply-notifications update):
1. In **Command Prompt**:
   ```
   cd C:\Users\rahul\Desktop\Apps\arena
   firebase deploy --only functions
   ```
   Wait for **✔ Deploy complete!**
2. **Publish the Firestore rules** (needed for the admin topic override): open the
   Firebase console → **Firestore → Rules**, paste the contents of
   `firestore.rules` from the repo, and click **Publish**. (It adds a `config/*`
   rule so every phone can read the admin's topic and only your admin account can
   set it.)
3. Rebuild the app onto the phone.

**Admin topic:** sign in as `cryptork97@gmail.com` → a "Push trending topic" box
appears on the rooms list. Type a topic, keep "default time (9 AM)" on (or pick a
time), tap **Push** → it replaces the next daily topic for everyone.

**Trending test:** get a room busy (~20 messages within 30 min); people who
opened that room but aren't currently in it get a "🔥 on fire" push (max once
per room every 3 hours).

---

## Updating — turning on "reply to your message" notifications

Newer builds also notify you when **someone replies to your message** (even if
you don't follow that room). The app side is already built; you just need to
**re-upload the notification function once more** and rebuild the app.

You've done all the one-time setup above already, so this is quick:

1. Open **Command Prompt** and go to the Arena folder:
   ```
   cd C:\Users\rahul\Desktop\Apps\arena
   ```
2. Re-upload the function (same command as before):
   ```
   firebase deploy --only functions
   ```
   Wait for **✔ Deploy complete!**
3. Rebuild the app onto your phone (see `TESTING.md`) so it starts subscribing
   you to your personal reply alerts.

**How to test it (needs two accounts):** on Phone A, post a message in a room.
On Phone B (a different account), **swipe that message to reply** and send.
Phone A should get a **"<name> replied to you"** notification — even if Phone A
never tapped the room's 🔔 bell. (You won't get one for replying to yourself.)

> Note: if you DO follow a room (🔔 on) and someone replies to you there, you may
> get two alerts — the room alert and the reply alert. That's expected for now.

---

## If something goes wrong

- `firebase: command not found` → redo Step 3, then close and reopen Command
  Prompt.
- Deploy says billing/Blaze required → redo Step 1.
- Deploy asks to enable "Cloud Build" or "Artifact Registry" APIs → say yes.
- Still stuck → tell me the exact message you see and I'll walk you through it.
