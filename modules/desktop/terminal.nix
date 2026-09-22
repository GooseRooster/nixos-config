{ config, lib, pkgs, ... }:

let
  # Launch a terminal app in Ghostty with zsh's environment bootstrapped.
  # Ghostty's `-e` sets initial-command, which replaces the `command =
  # <shell>` setting, so a bare `ghostty -e nvim` skips shell init entirely.
  # Wrapping the command in `zsh -l -c` restores login env — .zshrc is
  # interactive-only, so shell aliases/functions aren't loaded, but that's
  # fine for binary targets (nvim, yazi).
  termapp = pkgs.writeScriptBin "termapp" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.ghostty}/bin/ghostty
    fi
    exec ${pkgs.ghostty}/bin/ghostty -e ${pkgs.zsh}/bin/zsh -l -c "$*"
  '';
in
{
  environment.systemPackages = with pkgs; [
    ghostty        # terminal emulator
    wl-clipboard   # wl-copy / wl-paste
    brightnessctl  # backlight control
    termapp        # launch a terminal app in ghostty with zsh env bootstrapped
  ];

  # Make Ghostty the default terminal. GNOME 50's GLib no longer reads
  # org.gnome.desktop.default-applications.terminal for `Terminal=true` .desktop
  # entries (e.g. neovim) — it tries `xdg-terminal-exec` first from a hardcoded
  # list, so point that at Ghostty's desktop entry.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };
}
