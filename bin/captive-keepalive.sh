#!/usr/bin/env bash
# captive-keepalive.sh — stay connected through a UniFi "click to continue"
# guest portal by replaying the authorize request whenever the session expires.
#
# Works on any UniFi guest hotspot whose portal authorizes the client with an
# empty POST to .../login (the no-account "I accept / Continue" flow — it grants
# access by your device's MAC, no token or password). The portal address is
# auto-discovered from the captive-portal redirect, so this isn't tied to one
# venue; pass a login URL explicitly to override discovery.
#
# Usage:
#   captive-keepalive.sh                  # auto-discover portal, poll every 30s
#   captive-keepalive.sh <login-url>      # force a specific login endpoint
#   INTERVAL=15 captive-keepalive.sh      # override poll interval (seconds)
#
# Example login URL (UniFi default site):
#   http://192.168.1.1:8880/guest/s/default/login
#
# It sits quiet while you're online and only fires when it detects you've been
# kicked. Stop with Ctrl-C.

set -u

PROBE="http://captive.apple.com/hotspot-detect.html"   # returns "Success" only when truly online
INTERVAL="${INTERVAL:-30}"
LOGIN_URL="${1:-${CAPTIVE_LOGIN_URL:-}}"

online() {
  [[ "$(curl -s -m 5 "$PROBE")" == *Success* ]]
}

# Derive the UniFi login endpoint from the captive redirect.
# When intercepted, the probe 302s to e.g. http://192.168.1.1:8880/guest/s/default/?ap=...
# We strip the query and trailing slash, then append /login.
discover_login_url() {
  local loc
  loc=$(curl -s -m 5 -o /dev/null -w '%{redirect_url}' "$PROBE")
  loc="${loc%%\?*}"
  loc="${loc%/}"
  [[ -n "$loc" ]] && printf '%s/login\n' "$loc"
}

reauth() {
  curl -s -m 5 -X POST "$1" -H 'Content-Length: 0' >/dev/null 2>&1
}

echo "$(date '+%H:%M:%S') captive-keepalive started (every ${INTERVAL}s)"
[[ -n "$LOGIN_URL" ]] && echo "             login endpoint: $LOGIN_URL (fixed)"

while true; do
  if ! online; then
    url="$LOGIN_URL"
    [[ -z "$url" ]] && url="$(discover_login_url)"
    if [[ -n "$url" ]]; then
      echo "$(date '+%H:%M:%S') portal expired — re-authing via $url"
      reauth "$url"
      sleep 3
      if online; then
        echo "$(date '+%H:%M:%S') back online ✓"
      else
        echo "$(date '+%H:%M:%S') re-auth failed — portal may need a manual click this time"
      fi
    else
      echo "$(date '+%H:%M:%S') offline and couldn't discover portal URL — pass one as an argument"
    fi
  fi
  sleep "$INTERVAL"
done
