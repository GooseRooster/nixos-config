{ pkgs, ... }:

# Watches for a stable oo7 release so the beta pin in pkgs/oo7-beta.nix can be
# dropped. Two signals are checked daily in the user session:
#   - upstream: the latest non-prerelease GitHub release of linux-credentials/oo7
#   - nixpkgs:  the oo7 version on nixos-unstable (when it ships >= 0.7 the
#               overlay becomes redundant even before we bump our own nixpkgs)
# A desktop notification is sent once per new finding; the last finding is
# tracked in $XDG_STATE_HOME/oo7-watch/last so it doesn't nag every day.
let
  # First version at which the 0.6.0 deadlock (the reason for the pin) is fixed.
  minVersion = "0.7.0";

  oo7Watch = pkgs.writeShellApplication {
    name = "oo7-release-watch";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gnugrep
      gnused
      jq
      libnotify
    ];
    text = ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/oo7-watch"
      state_file="$state_dir/last"
      mkdir -p "$state_dir"

      curl_opts=(--fail --silent --show-error --location --max-time 20)

      upstream="$(
        curl "''${curl_opts[@]}" \
          https://api.github.com/repos/linux-credentials/oo7/releases/latest \
          | jq -r '.tag_name // empty' || true
      )"
      upstream="''${upstream#v}"

      nixpkgs="$(
        curl "''${curl_opts[@]}" \
          https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/by-name/oo/oo7/package.nix \
          | sed -n 's/^[[:space:]]*version = "\([^"]*\)".*/\1/p' | head -n1 || true
      )"

      # $1 >= $2 (GNU version sort)
      version_ge() {
        [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
      }

      findings=()
      if [ -n "$upstream" ] && version_ge "$upstream" "${minVersion}"; then
        findings+=("upstream stable release $upstream")
      fi
      if [ -n "$nixpkgs" ] && version_ge "$nixpkgs" "${minVersion}"; then
        findings+=("nixpkgs oo7 $nixpkgs")
      fi

      if [ "''${#findings[@]}" -eq 0 ]; then
        echo "oo7 still beta (upstream=''${upstream:-unknown} nixpkgs=''${nixpkgs:-unknown})"
        exit 0
      fi

      summary="$(printf '%s; ' "''${findings[@]}")"
      if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$summary" ]; then
        exit 0
      fi

      message="oo7 ${minVersion} is available (''${summary}). You can likely drop pkgs/oo7-beta.nix."
      echo "$message"

      # Only record the finding once the notification actually went out, so a
      # missed notification (session not ready yet) is retried on the next run.
      if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && \
         notify-send -a oo7-watch "oo7 out of beta" "$message"; then
        printf '%s' "$summary" > "$state_file"
      else
        echo "warning: could not send notification; will retry next run" >&2
      fi
    '';
  };
in
{
  systemd.user.services.oo7-release-watch = {
    description = "Check whether a stable oo7 release is available";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${oo7Watch}/bin/oo7-release-watch";
    };
  };

  systemd.user.timers.oo7-release-watch = {
    description = "Daily check for a stable oo7 release";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      # Give the session a moment to come up (matters for the Persistent
      # catch-up run at login) and spread out the request.
      RandomizedDelaySec = "1h";
    };
  };
}
