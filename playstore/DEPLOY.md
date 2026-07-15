# Arena — one-command deploy to Google Play

Ship future updates without clicking through the Play Console. `deploy.py` uses
the official **Google Play Developer API** to upload a signed `.aab` and roll it
out to a track.

> ⚠️ Do NOT use browser-clicking bots on the Play Console — it's behind Google
> login/2FA and Google flags automation on account pages (account-lock risk).
> This uses the *sanctioned* API instead.

---

## One-time setup

### 1. Python libraries
```
pip install google-api-python-client google-auth
```

### 2. Create a service account with Play access
1. **Play Console → Setup → API access**
2. Link (or create) a **Google Cloud project** when prompted.
3. Under **Service accounts** → **Create new service account** → this opens
   Google Cloud Console → create the service account (no roles needed there) →
   create a **JSON key** → download it.
4. Back in **Play Console → API access**, find the service account → **Grant
   access** → give it at least **Release apps to testing tracks** and **Release
   to production** (or Admin) → **Invite / Apply**.

### 3. Save the key (kept out of git)
Save the downloaded JSON as:
```
playstore/play-service-account.json
```
(Already gitignored — never commit it. Also back it up to the private Drive
folder like the keystore.)

---

## Releasing an update (every time)

1. **Bump the version** in `pubspec.yaml` — the build number after `+` must
   increase every upload, e.g. `1.0.0+2` → `1.0.0+3`.
2. Run one command:

```
# build + push to internal testing (fastest, instant):
python playstore/deploy.py --build --track internal --notes "What changed"

# push an already-built AAB to production (100%):
python playstore/deploy.py --track production --notes "What changed"

# staged production rollout (20% of users):
python playstore/deploy.py --track production --rollout 0.2 --notes "..."
```

Tracks: `internal` (up to 100 testers, instant), `alpha` = your **closed**
testing track, `beta` = open testing, `production` = public.

That's it — the AAB uploads and the track is updated automatically.

---

## Signing note
Release builds are signed with the upload keystore via `android/key.properties`
(see the keystore backup in Drive → "Arena Keystore (PRIVATE)"). Keep that file
present on any machine you build from, or the AAB won't be signed for upload.

## Switching machines
`git clone` the repo, then restore two gitignored secrets from the private Drive
backup: `android/key.properties` (+ the `.jks` it points to) and
`playstore/play-service-account.json`. Then `deploy.py` works as above.
