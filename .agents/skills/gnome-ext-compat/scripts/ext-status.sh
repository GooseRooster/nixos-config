#!/usr/bin/env bash
# GNOME Shell extension compatibility report.
#
# For every installed extension, checks declared shell-version support against:
#   1. the RUNNING shell version (gnome-shell --version)
#   2. the TARGET shell version of the nixpkgs rev pinned in flake.lock
#      (nix eval github:nixos/nixpkgs/<rev>#gnome-shell.version)
# plus, when online:
#   3. extensions.gnome.org — is there a published version supporting the target?
#   4. the extension's GitHub repo — does upstream metadata.json (default
#      branch) declare support for the target? (covers source-built extensions
#      that aren't on EGO)
#
# Exit codes: 0 = all fine, 1 = at least one extension broken for the target.
set -u

JQ="${JQ:-jq}"
CURL="${CURL:-curl}"
NIX="${NIX:-nix}"
EGO_BASE="https://extensions.gnome.org"

# ---------------------------------------------------------------- helpers ---
version()   { gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1; }
die()       { echo "error: $*" >&2; exit 2; }
have()      { command -v "$1" >/dev/null 2>&1; }

have "$JQ"   || die "jq not found"
have "$CURL" || die "curl not found"
have gnome-shell || die "gnome-shell not found"

RUN_MAJOR="$(version)" || die "cannot read running shell version"
[ -n "$RUN_MAJOR" ] || die "cannot read running shell version"

# The flake.lock to inspect: $1 or the nixos-config repo default.
FLAKE_LOCK="${1:-$HOME/.config/nixos-config/flake.lock}"
TARGET_MAJOR=""
if [ -f "$FLAKE_LOCK" ] && have "$NIX"; then
  REV="$($JQ -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev // .nodes[.nodes.root.inputs.nixpkgs].original.rev // empty' "$FLAKE_LOCK" 2>/dev/null)"
  if [ -n "$REV" ]; then
    TARGET_MAJOR="$("$NIX" eval --raw "github:nixos/nixpkgs/$REV#gnome-shell.version" 2>/dev/null | grep -oE '^[0-9]+' || true)"
  fi
fi
OFFLINE_NIX=$([ -z "$TARGET_MAJOR" ] && echo yes || echo no)

# --------------------------------------------------------- data collection ---
# Installed extension dirs: system profile first, then user dir (dedup by uuid).
SYS_DIR="/run/current-system/sw/share/gnome-shell/extensions"
USER_DIR="$HOME/.local/share/gnome-shell/extensions"

declare -a UUIDS=() NAMES=() IVS=() SVS=() URLS=()
seen=""

collect() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local meta uuid name iver url
  for meta in "$dir"/*/metadata.json; do
    [ -f "$meta" ] || continue
    uuid=$($JQ -r '.uuid // empty' "$meta") || continue
    [ -n "$uuid" ] || continue
    case ",$seen," in *",uuid,"*) continue ;; esac
    seen="$seen,$uuid"
    name=$($JQ -r '.name // "?"' "$meta")
    iver=$($JQ -r '."version-name" // .version // "?"' "$meta")
    url=$($JQ -r '.url // empty' "$meta")
    UUIDS+=("$uuid"); NAMES+=("$name"); IVS+=("$iver"); URLS+=("$url")
    SVS+=("$($JQ -c '.["shell-version"] // []' "$meta")")
  done
}

collect "$SYS_DIR"
collect "$USER_DIR"
[ ${#UUIDS[@]} -gt 0 ] || die "no installed extensions found"

# ------------------------------------------------------------ web lookups ---
ego_version_for() { # uuid, major -> "vN" | "none" | "-" (not on EGO) | "off"
  local q enc
  enc=$(printf '%s' "$1" | sed 's/@/%40/')
  q=$("$CURL" -sf --max-time 10 "$EGO_BASE/extension-query/?uuid=$enc") || { echo "off"; return; }
  echo "$q" | $JQ -r --arg m "$2" '
    if (.extensions | length) == 0 then "-"
    elif .extensions[0].shell_version_map[$m].version then "v\(.extensions[0].shell_version_map[$m].version)"
    else "none" end'
}

git_supports() { # url, major -> "yes" | "no" | "-" (no github url / error)
  case "$1" in
    https://github.com/*) local repo=${1#https://github.com/} ;;
    *) echo "-"; return ;;
  esac
  repo=${repo%%/wiki}
  # raw.githubusercontent (no API rate limits); HEAD resolves the default branch.
  local sup
  sup=$("$CURL" -sfL --max-time 10 "https://raw.githubusercontent.com/$repo/HEAD/metadata.json" 2>/dev/null |
    $JQ -r --arg m "$2" 'any(.["shell-version"][]?; tostring == $m)' 2>/dev/null)
  case "$sup" in true) echo yes ;; false) echo no ;; *) echo - ;; esac
}

# -------------------------------------------------------------- evaluation ---
declare -a NOW=() POST=() EGO=() GIT=()
ONLINE=1
"$CURL" -sf --max-time 5 "$EGO_BASE" >/dev/null 2>&1 || ONLINE=0

in_list() { # json-list, major
  echo "$1" | $JQ -e --arg m "$2" 'any(.[]?; tostring == $m)' >/dev/null 2>&1
}

for i in "${!UUIDS[@]}"; do
  u=${UUIDS[$i]}
  if in_list "${SVS[$i]}" "$RUN_MAJOR"; then NOW+=("OK"); else NOW+=("BROKEN"); fi

  if [ -n "$TARGET_MAJOR" ]; then
    if in_list "${SVS[$i]}" "$TARGET_MAJOR"; then POST+=("OK"); else POST+=("BROKEN"); fi
  else
    POST+=("?")
  fi

  if [ "$ONLINE" = 1 ]; then
    ev="-"
    if [ -n "$TARGET_MAJOR" ]; then
      ev=$(ego_version_for "$u" "$TARGET_MAJOR")
    fi
    EGO+=("$ev")
  else
    EGO+=("off")
  fi

  if [ "$ONLINE" = 1 ] && [ -n "${URLS[$i]}" ]; then
    GIT+=("$(git_supports "${URLS[$i]}" "${TARGET_MAJOR:-$RUN_MAJOR}")")
  else
    GIT+=("-")
  fi
done

# ------------------------------------------------------------------ output ---
echo "GNOME Shell extension compatibility"
echo "  running:  $RUN_MAJOR"
if [ -n "$TARGET_MAJOR" ]; then
  echo "  target:   $TARGET_MAJOR  (nixpkgs rev pinned in $(basename "$FLAKE_LOCK"))"
else
  echo "  target:   n/a ($([ "$OFFLINE_NIX" = yes ] && echo 'no flake.lock/nix or offline'))"
fi
echo
fmt='%-45s %-10s %-5s %-14s %-12s %-6s\n'
printf "$fmt" EXTENSION INSTALLED NOW "POST-REBUILD" "EGO(update)" GIT
printf "$fmt" "$(printf '%.0s-' {1..45})" "$(printf '%.0s-' {1..10})" "$(printf '%.0s-' {1..5})" "$(printf '%.0s-' {1..14})" "$(printf '%.0s-' {1..12})" "$(printf '%.0s-' {1..6})"
rc=0
for i in "${!UUIDS[@]}"; do
  printf "$fmt" "${UUIDS[$i]}" "${IVS[$i]}" "${NOW[$i]}" "${POST[$i]}" "${EGO[$i]}" "${GIT[$i]}"
  if [ "${POST[$i]}" = BROKEN ] || [ "${NOW[$i]}" = BROKEN ]; then rc=1; fi
done
echo
notes=()
[ "$ONLINE" = 0 ] && notes+=("offline: EGO/Git checks skipped")
[ "$OFFLINE_NIX" = yes ] && notes+=("target shell unknown: nix eval unavailable (offline, no flake.lock, or no nix)")
[ ${#notes[@]} -gt 0 ] && printf 'note: %s\n' "${notes[@]}"

# Post-rebuild guidance only when the target actually differs.
if [ -n "$TARGET_MAJOR" ] && [ "$TARGET_MAJOR" != "$RUN_MAJOR" ]; then
  if [ $rc -eq 1 ]; then
    echo "=> BROKEN extensions will not load after the rebuild."
    echo "   org.gnome.shell disable-extension-version-validation=true (a dconf default"
    echo "   in this config) force-loads them anyway — check EGO/Git columns for updates first."
  else
    echo "=> all extensions declare support for the target shell."
  fi
fi
exit $rc
