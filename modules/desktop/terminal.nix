{ config, lib, pkgs, ... }:

let
  # Launch a terminal app in Ghostty with the nushell environment bootstrapped
  # (env.nu sets $EDITOR, $SSH_AUTH_SOCK, carapace/zoxide init, etc.). Ghostty's
  # `-e` sets initial-command, which replaces the `command = nu` shell — so a
  # bare `ghostty -e nvim` would skip env.nu. Wrapping the command in `nu -c`
  # restores the bootstrap for .desktop `Terminal=true` entries and GNOME
  # keyboard shortcuts.
  termapp = pkgs.writeScriptBin "termapp" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.ghostty}/bin/ghostty
    fi
    exec ${pkgs.ghostty}/bin/ghostty -e ${pkgs.nushell}/bin/nu -c "$*"
  '';
in
{
  environment.systemPackages = with pkgs; [
    ghostty        # terminal emulator
    wl-clipboard   # wl-copy / wl-paste
    brightnessctl  # backlight control
    termapp        # launch a terminal app in ghostty with nu env bootstrapped
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
