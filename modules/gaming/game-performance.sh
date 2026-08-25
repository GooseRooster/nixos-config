#!/usr/bin/env bash
#
# game-performance — switch to a "performance" TuneD profile while a Steam
# game runs, then restore whatever was active before. Also disables GNOME
# Night Light for the duration and restores it.
#
# Generated as a NixOS module (modules/gaming/game-performance.nix), which
# substitutes the @...@ placeholders with absolute store paths and the TuneD
# profile. No PATH or /etc/tuned/ppd.conf assumptions — those were
# Bluefin-specific and silently failed on NixOS (host tools live under
# /run/current-system/sw/bin, which flatpak-spawn --host doesn't have on its
# PATH).
#
# Steam: Properties -> General -> Launch Options:
#   ~/.local/bin/game-performance %command%
#
# Runs inside Steam's Flatpak sandbox, so host-side commands are routed out
# via flatpak-spawn --host. Requires:
#   flatpak --user override --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam
#   flatpak --user override --filesystem=~/.local/bin:ro com.valvesoftware.Steam

set -uo pipefail

TUNED_ADM="@tunedAdm@"
GSETTINGS="@gsettings@"
NOTIFY_SEND="@notifySend@"
PERF_PROFILE="@perfProfile@"

# Detect whether we're inside a Flatpak sandbox; fall back to running
# commands directly if not (e.g. testing this script from a bare terminal).
if [[ -f /.flatpak-info ]] && command -v flatpak-spawn &>/dev/null; then
  host() { flatpak-spawn --host "$@"; }
else
  host() { "$@"; }
fi

notify() {
  host "$NOTIFY_SEND" -a "game-performance" -i "$1" -t 4000 "$2" "$3" 2>/dev/null
}

if ! active_line="$(host "$TUNED_ADM" active 2>/dev/null)"; then
  echo "game-performance: tuned-adm unavailable, launching unmodified" >&2
  exec "$@"
fi

prev_profile="${active_line#Current active profile: }"

# --- Night Light state -------------------------------------------------
NIGHT_LIGHT_SCHEMA="org.gnome.settings-daemon.plugins.color"
NIGHT_LIGHT_KEY="night-light-enabled"

night_light_prev="$(host "$GSETTINGS" get "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" 2>/dev/null)"

restore_profile() {
  if host "$TUNED_ADM" profile "$prev_profile" 2>/dev/null; then
    notify "power-profile-balanced-symbolic" "Power profile restored" "$prev_profile"
  fi
  if [[ -n "$night_light_prev" ]]; then
    host "$GSETTINGS" set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" "$night_light_prev" 2>/dev/null
  fi
}

trap restore_profile EXIT INT TERM

if [[ "$prev_profile" != "$PERF_PROFILE" ]]; then
  if host "$TUNED_ADM" profile "$PERF_PROFILE" 2>/dev/null; then
    notify "power-profile-performance-symbolic" "Performance mode" "$PERF_PROFILE for this game"
  else
    echo "game-performance: couldn't switch to '$PERF_PROFILE' profile" >&2
  fi
fi

if [[ "$night_light_prev" == "true" ]]; then
  host "$GSETTINGS" set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" false 2>/dev/null
fi

"$@"
exit_code=$?
exit "$exit_code"
