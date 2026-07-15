#!/usr/bin/env python3
"""
One-command Arena release to Google Play via the Play Developer API.

Uploads a signed .aab and rolls it out to a track (internal / alpha / beta /
production). No manual Play Console clicking for future updates.

Prereqs (one-time, see DEPLOY.md):
  1. A Google Cloud service account with Play Console access.
  2. Its JSON key saved as playstore/play-service-account.json  (gitignored).
  3. pip install google-api-python-client google-auth

Usage:
  # build first, then deploy the fresh AAB to internal testing:
  python playstore/deploy.py --build --track internal --notes "Bug fixes"

  # deploy an already-built AAB to production at 100%:
  python playstore/deploy.py --track production
"""
import argparse
import subprocess
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

REPO = Path(__file__).resolve().parent.parent
PACKAGE = "com.cryptork.arena"
DEFAULT_AAB = REPO / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
DEFAULT_KEY = REPO / "playstore" / "play-service-account.json"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def flutter_build():
    """Build the release AAB with Flutter."""
    print(">> flutter build appbundle --release")
    flutter = "flutter"  # assumes flutter is on PATH; edit if needed
    r = subprocess.run([flutter, "build", "appbundle", "--release"], cwd=REPO)
    if r.returncode != 0:
        sys.exit("Flutter build failed.")


def main():
    ap = argparse.ArgumentParser(description="Deploy Arena to Google Play.")
    ap.add_argument("--track", default="internal",
                    choices=["internal", "alpha", "beta", "production"],
                    help="Play track to release to (default: internal).")
    ap.add_argument("--aab", default=str(DEFAULT_AAB), help="Path to the .aab.")
    ap.add_argument("--key", default=str(DEFAULT_KEY),
                    help="Service account JSON key path.")
    ap.add_argument("--notes", default="", help="Release notes (en-US).")
    ap.add_argument("--build", action="store_true",
                    help="Run 'flutter build appbundle --release' first.")
    ap.add_argument("--rollout", type=float, default=1.0,
                    help="Fraction to roll out for production (0.0-1.0, default 1.0).")
    args = ap.parse_args()

    if args.build:
        flutter_build()

    aab = Path(args.aab)
    key = Path(args.key)
    if not key.exists():
        sys.exit(f"Service account key not found: {key}\nSee playstore/DEPLOY.md.")
    if not aab.exists():
        sys.exit(f"AAB not found: {aab}\nRun with --build, or build the app first.")

    creds = service_account.Credentials.from_service_account_file(
        str(key), scopes=SCOPES)
    service = build("androidpublisher", "v3", credentials=creds,
                    cache_discovery=False)
    edits = service.edits()

    print(f">> Opening edit for {PACKAGE}")
    edit_id = edits.insert(body={}, packageName=PACKAGE).execute()["id"]

    print(f">> Uploading {aab.name} ({aab.stat().st_size/1_048_576:.1f} MB)")
    media = MediaFileUpload(str(aab), mimetype="application/octet-stream",
                            resumable=True)
    bundle = edits.bundles().upload(
        packageName=PACKAGE, editId=edit_id, media_body=media).execute()
    version_code = bundle["versionCode"]
    print(f"   uploaded versionCode {version_code}")

    release = {"name": f"v{version_code}", "versionCodes": [str(version_code)],
               "status": "completed"}
    if args.track == "production" and args.rollout < 1.0:
        release["status"] = "inProgress"
        release["userFraction"] = args.rollout
    if args.notes:
        release["releaseNotes"] = [{"language": "en-US", "text": args.notes}]

    print(f">> Assigning versionCode {version_code} to '{args.track}' track")
    edits.tracks().update(
        packageName=PACKAGE, editId=edit_id, track=args.track,
        body={"track": args.track, "releases": [release]}).execute()

    print(">> Committing edit")
    edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    print(f"\nDONE. versionCode {version_code} is live on the '{args.track}' track.")


if __name__ == "__main__":
    main()
