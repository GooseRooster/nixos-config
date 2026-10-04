{
  config,
  pkgs,
  ...
}:

# GPU Screen Recorder plumbing. The recorder is the native nixpkgs package,
# enabled below via programs.gpu-screen-recorder so nixpkgs generates a setcap
# wrapper for gsr-kms-server (cap_sys_admin+ep). That capability is what lets
# monitor and region capture reach KMS without a root/polkit prompt; the
# Flatpak route has to prompt once because a sandbox can't carry the
# capability. Two commands:
#
#   gsr-shot [region|full] [clip|edit]
#     screenshot via GSR (HDR-correct, unlike grim); clip copies the PNG to the
#     clipboard + notifies, edit hands it to Gradia when that flatpak is
#     present.
#
#   gsr-rec [--mic] <screen|region|stop>
#     screen recording, detached; stop SIGINTs the running recorder.
#
# The keybindings that call these live in the base Sway config
# (modules/desktop/sway-base.conf) and are duplicated in the dotfiles HM sway
# module. Scripts are at the system level so a bare install (or a fork without
# the user's Home-Manager config) still has working screenshots/recording.
let
  gsr = config.programs.gpu-screen-recorder.package;

  gsr-shot = pkgs.writeShellApplication {
    name = "gsr-shot";
    runtimeInputs = with pkgs; [
      slurp
      wl-clipboard
      libnotify
      coreutils
      flatpak
      gsr
    ];
    text = ''
      mode="''${1:-region}"    # region | full
      action="''${2:-clip}"    # clip | edit

      dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$dir"
      file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

      case "$mode" in
        region)
          # slurp's default format is "X,Y WxH"; GSR wants "WxH+X+Y".
          region="$(slurp -f '%wx%h+%x+%y')" || exit 0
          [ -n "$region" ] || exit 0
          src=(-w "$region")
          ;;
        full)
          src=(-w screen)
          ;;
        *)
          echo "usage: gsr-shot [region|full] [clip|edit]" >&2
          exit 2
          ;;
      esac

      # Capture stderr so a failed run can report the real reason. The wrapper
      # is `set -e`, which would otherwise abort before notifying the user.
      if ! err="$(gpu-screen-recorder \
        "''${src[@]}" -o "$file" 2>&1 >/dev/null)"; then
        rm -f "$file"
        notify-send -a "Screenshot" -u critical "Screenshot failed" \
          "''${err:-GPU Screen Recorder returned an error}"
        exit 1
      fi

      if [ ! -s "$file" ]; then
        notify-send -a "Screenshot" -u critical "Screenshot failed" \
          "No image was written to $file"
        exit 1
      fi

      case "$action" in
        clip)
          wl-copy --type image/png < "$file"
          notify-send -a "Screenshot" -i "$file" \
            "Screenshot copied to clipboard" "$(basename "$file")"
          ;;
        edit)
          # Gradia is a user-facing flatpak (not part of the system baseline),
          # so degrade gracefully when it isn't installed.
          if flatpak info be.alexandervanhee.gradia >/dev/null 2>&1; then
            flatpak run be.alexandervanhee.gradia "$file"
          else
            notify-send -a "Screenshot" "Image editor not installed" \
              "Install be.alexandervanhee.gradia to edit screenshots"
          fi
          ;;
      esac
    '';
  };

  gsr-rec = pkgs.writeShellApplication {
    name = "gsr-rec";
    runtimeInputs = with pkgs; [
      slurp
      libnotify
      coreutils
      gnugrep
      procps
      util-linux
      gsr
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/gsr-rec.state"

      is_recording() {
        pgrep -f 'gpu-screen-recorder -w' >/dev/null 2>&1
      }

      mic=0
      if [ "''${1:-}" = "--mic" ]; then
        mic=1
        shift
      fi
      mode="''${1:-}"

      if [ "$mode" = stop ]; then
        if ! is_recording; then
          rm -f "$state"
          notify-send -a "Recorder" -u low "No recording in progress"
          exit 0
        fi

        pkill -INT -f 'gpu-screen-recorder -w'

        # Wait for GSR to finalize the file before reporting the path.
        for _ in $(seq 1 100); do
          is_recording || break
          sleep 0.1
        done

        file=""
        [ -f "$state" ] && file="$(cat "$state")"
        rm -f "$state" "$state.log"

        if [ -n "$file" ]; then
          notify-send -a "Recorder" -i camera-video \
            "Recording saved" "$(basename "$file")"
        else
          notify-send -a "Recorder" "Recording stopped"
        fi
        exit 0
      fi

      if is_recording; then
        notify-send -a "Recorder" -u low "Already recording" \
          "Stop the current recording first"
        exit 0
      fi

      case "$mode" in
        screen)
          src=(-w screen)
          ;;
        region)
          region="$(slurp -f '%wx%h+%x+%y')" || exit 0
          [ -n "$region" ] || exit 0
          src=(-w "$region")
          ;;
        *)
          echo "usage: gsr-rec [--mic] <screen|region|stop>" >&2
          exit 2
          ;;
      esac

      if [ "$mic" = 1 ]; then
        audio=(-a "default_output|default_input")
      else
        audio=(-a default_output)
      fi

      dir="$HOME/Videos"
      mkdir -p "$dir"
      file="$dir/Video_$(date +%Y-%m-%d_%H-%M-%S).mp4"
      log="$state.log"
      printf '%s' "$file" > "$state"

      # setsid detaches it from sway's exec shell so the recording survives.
      # Output is logged so a failed start can report the actual error.
      setsid gpu-screen-recorder \
        "''${src[@]}" -c mp4 -f 60 -q very_high -cr full -cursor yes \
        "''${audio[@]}" -o "$file" </dev/null >"$log" 2>&1 &

      # Only report success once GSR is genuinely capturing. GSR logs
      # "update fps" once frames are flowing through the encoder, whereas a
      # failed startup (e.g. no VA-API driver) logs "gsr error" and exits
      # within a fraction of a second. The old check trusted liveness the
      # instant the process appeared, so it reported "started" for a recorder
      # that died moments later, then deleted the log on stop.
      started=0
      for _ in $(seq 1 40); do
        is_recording || break
        if grep -q 'update fps' "$log" 2>/dev/null; then
          started=1
          break
        fi
        sleep 0.1
      done

      # Fallback for a recorder that is alive past the handshake window but
      # has not emitted a stats line yet, as long as it logged no error.
      if [ "$started" = 0 ] && is_recording \
        && ! grep -q 'gsr error' "$log" 2>/dev/null; then
        started=1
      fi

      if [ "$started" = 1 ]; then
        notify-send -a "Recorder" -i camera-video \
          "Recording started" "$(basename "$file")"
        exit 0
      fi

      err="$(tail -n 8 "$log" 2>/dev/null)"
      notify-send -a "Recorder" -u critical "Recording failed" \
        "''${err:-GPU Screen Recorder failed to start}"
      rm -f "$file" "$state" "$log"
      exit 1
    '';
  };
in
{
  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = [
    gsr-shot
    gsr-rec
  ];
}
