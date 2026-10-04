{
  pkgs,
  ...
}:

# GPU Screen Recorder plumbing, owned by the "distro" layer because the
# recorder is a *system* Flatpak (modules/flatpak/system.nix). Two commands:
#
#   gsr-shot [region|full] [clip|edit]
#     screenshot via the GSR flatpak (HDR-correct, unlike grim); clip copies
#     the PNG to the clipboard + notifies, edit hands it to Gradia when that
#     flatpak is present.
#
#   gsr-rec [--mic] <screen|region|stop>
#     screen recording, detached; stop SIGINTs the running recorder.
#
# The keybindings that call these live in the base Sway config
# (modules/desktop/sway-base.conf) and are duplicated in the dotfiles HM sway
# module. Scripts are at the system level so a bare install (or a fork without
# the user's Home-Manager config) still has working screenshots/recording.
let
  gsrApp = "com.dec05eba.gpu_screen_recorder";

  gsr-shot = pkgs.writeShellApplication {
    name = "gsr-shot";
    runtimeInputs = with pkgs; [
      slurp
      wl-clipboard
      libnotify
      coreutils
      flatpak
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

      flatpak run --command=gpu-screen-recorder ${gsrApp} \
        "''${src[@]}" -o "$file"

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
      procps
      util-linux
      flatpak
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
        rm -f "$state"

        if [ -n "$file" ]; then
          notify-send -a "Recorder" -i "${gsrApp}" \
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
      printf '%s' "$file" > "$state"

      # setsid detaches it from sway's exec shell so the recording survives.
      setsid flatpak run --command=gpu-screen-recorder ${gsrApp} \
        "''${src[@]}" -c mp4 -f 60 -q very_high -cr full -cursor yes \
        "''${audio[@]}" -o "$file" </dev/null >/dev/null 2>&1 &

      notify-send -a "Recorder" -i "${gsrApp}" \
        "Recording started" "$(basename "$file")"
    '';
  };
in
{
  environment.systemPackages = [
    gsr-shot
    gsr-rec
  ];
}
