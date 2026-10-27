#!/usr/bin/env bash
# Writes the CI-supplied iOS secrets into git-ignored files. Never prints values.
#
#   GOOGLE_SERVICE_INFO_PLIST  base64 of GoogleService-Info.plist -> ios/Runner/GoogleService-Info.plist
#   ADMOB_IOS_APP_ID           real AdMob iOS *app* id            -> ios/Flutter/Secrets.xcconfig
#   (derived) REVERSED_CLIENT_ID from the plist                   -> ios/Flutter/Secrets.xcconfig
#
# Flags: --allow-stub     no plist supplied: write a clearly fake one (compile-only CI builds)
#        --require-admob  fail unless ADMOB_IOS_APP_ID is set (release builds)
set -euo pipefail

PLIST="ios/Runner/GoogleService-Info.plist"
XCCONFIG="ios/Flutter/Secrets.xcconfig"
ALLOW_STUB=0
REQUIRE_ADMOB=0
for arg in "$@"; do
  case "$arg" in
    --allow-stub) ALLOW_STUB=1 ;;
    --require-admob) REQUIRE_ADMOB=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if [ -n "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
  printf '%s' "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > "$PLIST"
elif [ "$ALLOW_STUB" = "1" ]; then
  echo "WARNING: GOOGLE_SERVICE_INFO_PLIST not set; writing a STUB plist (build only, Firebase will not work)."
  python3 - "$PLIST" <<'PY'
import plistlib, sys
stub = {
    "GOOGLE_APP_ID": "1:000000000000:ios:0000000000000000",
    "GCM_SENDER_ID": "000000000000",
    "API_KEY": "stub",
    "PROJECT_ID": "stub",
    "BUNDLE_ID": "com.polatliajans.kriptoanaliz",
    "CLIENT_ID": "000000000000-stub.apps.googleusercontent.com",
    "REVERSED_CLIENT_ID": "com.googleusercontent.apps.000000000000-stub",
}
with open(sys.argv[1], "wb") as f:
    plistlib.dump(stub, f)
PY
else
  echo "ERROR: GOOGLE_SERVICE_INFO_PLIST (base64 of GoogleService-Info.plist) is not set." >&2
  exit 1
fi

# Validate the plist and extract the URL scheme needed by Google Sign-In.
REVERSED_CLIENT_ID="$(python3 - "$PLIST" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    data = plistlib.load(f)
for key in ("GOOGLE_APP_ID", "GCM_SENDER_ID", "BUNDLE_ID"):
    if not data.get(key):
        sys.exit("GoogleService-Info.plist is missing " + key)
if data["BUNDLE_ID"] != "com.polatliajans.kriptoanaliz":
    sys.exit("GoogleService-Info.plist BUNDLE_ID does not match com.polatliajans.kriptoanaliz")
rev = data.get("REVERSED_CLIENT_ID")
if not rev:
    sys.exit("REVERSED_CLIENT_ID missing: enable Google sign-in in Firebase and re-download the plist")
print(rev)
PY
)"

: > "$XCCONFIG"
echo "GOOGLE_REVERSED_CLIENT_ID = ${REVERSED_CLIENT_ID}" >> "$XCCONFIG"

if [ -n "${ADMOB_IOS_APP_ID:-}" ]; then
  if ! printf '%s' "$ADMOB_IOS_APP_ID" | grep -Eq '^ca-app-pub-[0-9]{16}~[0-9]{10}$'; then
    echo "ERROR: ADMOB_IOS_APP_ID must look like ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY (app id with '~', not an ad unit id)." >&2
    exit 1
  fi
  echo "ADMOB_IOS_APP_ID = ${ADMOB_IOS_APP_ID}" >> "$XCCONFIG"
elif [ "$REQUIRE_ADMOB" = "1" ]; then
  echo "ERROR: ADMOB_IOS_APP_ID is not set (release builds must not ship the Google test app id)." >&2
  exit 1
else
  echo "ADMOB_IOS_APP_ID not set: keeping the Google test app id from AppConfig.xcconfig."
fi
echo "iOS secrets written (values not printed)."
