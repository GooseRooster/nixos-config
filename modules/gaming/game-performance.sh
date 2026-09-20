#!/usr/bin/env bash
#
# game-performance — switch to a "performance" TuneD profile while a Steam
# game runs, then restore whatever was active before. Also disables Night
# Light for the duration (gsettings), restoring it afterwards.
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
#
# Steam prepends gameoverlayrenderer.so to LD_PRELOAD for launch-option
# commands (native Steam; the Flatpak version does the same for its own
# game processes). That .so depends on Steam Runtime libraries which don't
# resolve for host-side Nix binaries — every spawned process dies at loader
# stage with exit 127 ("libGL.so.1: cannot open shared object file"). Strip
# Steam's injected LD_* vars for host calls; the game itself (invoked
# directly at the bottom, not via host()) keeps them so the overlay works.
if [[ -f /.flatpak-info ]] && command -v flatpak-spawn &>/dev/null; then
  host() { env -u LD_PRELOAD -u LD_LIBRARY_PATH flatpak-spawn --host "$@"; }
else
  host() { env -u LD_PRELOAD -u LD_LIBRARY_PATH "$@"; }
fi

# Steam wraps the WHOLE launch-options command (this script included) in the
# game's SteamLinuxRuntime container: root on a private tmpfs with the
# container's own /etc, while /run stays a (slave) bind of the host's. Two
# consequences: /tmp writes vanish with the container, and /etc/tuned is
# missing, so tuned-adm dies with "Global TuneD configuration file
# '/etc/tuned/tuned-main.conf' not found" before it ever reaches the daemon.
# Everything that matters via the SESSION bus (notifications, dconf) works
# in-container, but TuneD is driven over the SYSTEM bus and
# needs host /etc — so when this script runs in a container, relay tuned-adm
# through the user's systemd manager (systemd-run --user), which executes it
# on the real host. Outside containers /etc/tuned exists and we call it
# directly.
tuned() {
  if [[ -r /etc/tuned/tuned-main.conf ]]; then
    host "$TUNED_ADM" "$@"
  elif [[ -x /run/current-system/sw/bin/systemd-run ]]; then
    host /run/current-system/sw/bin/systemd-run --user --pipe --wait "$TUNED_ADM" "$@"
  else
    return 127
  fi
}

notify() {
  host "$NOTIFY_SEND" -a "game-performance" -i "$1" -t 4000 "$2" "$3" 2>/dev/null
}

if ! active_line="$(tuned active 2>/dev/null)"; then
  echo "game-performance: tuned-adm unavailable, launching unmodified" >&2
  exec "$@"
fi

prev_profile="${active_line#Current active profile: }"

# --- Night Light state -------------------------------------------------
NIGHT_LIGHT_SCHEMA="org.gnome.settings-daemon.plugins.color"
NIGHT_LIGHT_KEY="night-light-enabled"

night_light_prev="$(host "$GSETTINGS" get "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" 2>/dev/null)"

restore_profile() {
  if tuned profile "$prev_profile" 2>/dev/null; then
    notify "power-profile-balanced-symbolic" "Power profile restored" "$prev_profile"
  fi
  if [[ -n "$night_light_prev" ]]; then
    host "$GSETTINGS" set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" "$night_light_prev" 2>/dev/null
  fi
}

trap restore_profile EXIT INT TERM

if [[ "$prev_profile" != "$PERF_PROFILE" ]]; then
  if tuned profile "$PERF_PROFILE" 2>/dev/null; then
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
