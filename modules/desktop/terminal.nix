{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Launch a terminal app in Foot with zsh's environment bootstrapped.
  # Foot's positional command replaces the configured shell, so a bare
  # `foot nvim` would skip shell init entirely. Wrapping the command in
  # `zsh -l -c` restores login env — .zshrc is interactive-only, so shell
  # aliases/functions aren't loaded, but that's fine for binary targets
  # (nvim, yazi). Foot's `-e` is accepted-and-ignored for xterm compatibility,
  # so the familiar `-e` form still works.
  termapp = pkgs.writeScriptBin "termapp" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.foot}/bin/foot
    fi
    exec ${pkgs.foot}/bin/foot -e ${pkgs.zsh}/bin/zsh -l -c "$*"
  '';
in
{
  environment.systemPackages = with pkgs; [
    foot # terminal emulator
    wl-clipboard # wl-copy / wl-paste
    brightnessctl # backlight control
    termapp # launch a terminal app in foot with zsh env bootstrapped
  ];

  # Make Foot the default terminal. GNOME 50's GLib no longer reads
  # org.gnome.desktop.default-applications.terminal for `Terminal=true` .desktop
  # entries (e.g. neovim) — it tries `xdg-terminal-exec` first from a hardcoded
  # list, so point that at Foot's desktop entry.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "foot.desktop" ];
  };
}
