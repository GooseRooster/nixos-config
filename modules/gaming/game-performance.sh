#!/usr/bin/env bash
#
# game-performance — switch to a "performance" TuneD profile while a Steam
# game runs, then restore whatever was active before. Also disables Night
# Light for the duration and enables caffeine (idle inhibitor), restoring
# both afterwards.
#
# Shell-aware: when Noctalia v5 is running, Night Light and caffeine are
# driven through its IPC (`noctalia msg ...`). Night Light state is read
# from Noctalia's persisted settings.toml (IPC toggles are persisted there
# and no status command exists) — a plain toggle would switch the schedule
# ON during a game when the user had it off. Caffeine is enabled/disabled
# unconditionally: there is no persisted state or status command, and the
# toggle variant would switch an already-enabled caffeine OFF mid-game.
# Without Noctalia (GNOME session / bare terminal) the gsettings Night Light
# path is used as before; caffeine is skipped there.
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
NOCTALIA="@noctalia@"
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

# Noctalia v5 IPC availability: probe with a read-only status command. The
# sandbox may not mount Noctalia's IPC socket, but the host-side invocation
# always sees it (and steam needs the flatpak-spawn talk permission anyway).
if host "$NOCTALIA" msg wifi-status &>/dev/null; then
  noctalia=true
else
  noctalia=false
fi

if ! active_line="$(host "$TUNED_ADM" active 2>/dev/null)"; then
  echo "game-performance: tuned-adm unavailable, launching unmodified" >&2
  exec "$@"
fi

prev_profile="${active_line#Current active profile: }"

# --- Night Light state -------------------------------------------------
NIGHT_LIGHT_SCHEMA="org.gnome.settings-daemon.plugins.color"
NIGHT_LIGHT_KEY="night-light-enabled"

night_light_prev="$(host "$GSETTINGS" get "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" 2>/dev/null)"

# The [nightlight] enabled value from Noctalia's persisted config:
# settings.toml (IPC/GUI toggles land there) wins over config.toml; "true"
# when nothing says otherwise, so a game never runs with the tint on by
# accident and an unknown state is restored to the schedule being on.
noctalia_nightlight_enabled() {
  local f v
  for f in "${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml" \
           "${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/config.toml"; do
    [[ -f "$f" ]] || continue
    v="$(awk '
      /^[[:space:]]*\[nightlight\][[:space:]]*$/ { in_section = 1; next }
      /^[[:space:]]*\[/ { in_section = 0 }
      in_section && /^[[:space:]]*enabled[[:space:]]*=/ {
        sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit
      }' "$f")"
    [[ -n "$v" ]] && { echo "$v"; return; }
  done
  echo "true"
}

nightlight_restore=false

restore_profile() {
  if host "$TUNED_ADM" profile "$prev_profile" 2>/dev/null; then
    notify "power-profile-balanced-symbolic" "Power profile restored" "$prev_profile"
  fi
  if [[ "$noctalia" == true ]]; then
    if [[ "$nightlight_restore" == true ]]; then
      host "$NOCTALIA" msg nightlight-enable 2>/dev/null
    fi
    host "$NOCTALIA" msg caffeine-disable 2>/dev/null
  elif [[ -n "$night_light_prev" ]]; then
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

if [[ "$noctalia" == true ]]; then
  if [[ "$(noctalia_nightlight_enabled)" == "true" ]]; then
    if host "$NOCTALIA" msg nightlight-disable 2>/dev/null; then
      nightlight_restore=true
    fi
  fi
  host "$NOCTALIA" msg caffeine-enable 2>/dev/null
elif [[ "$night_light_prev" == "true" ]]; then
  host "$GSETTINGS" set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" false 2>/dev/null
fi

"$@"
exit_code=$?
exit "$exit_code"
