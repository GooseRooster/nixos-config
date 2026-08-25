{ config, lib, pkgs, ... }:

let
  # Launch a terminal app in Ghostty with the nushell environment bootstrapped.
  # Ghostty's `-e` sets initial-command, which replaces the `command = nu` shell,
  # so a bare `ghostty -e nvim` skips nushell entirely. Wrapping the command in
  # `nu --login -c` restores the full startup (env.nu sets $EDITOR/$NVIM_PROFILE/
  # $SSH_AUTH_SOCK, config.nu defines aliases/functions like `y` and sources the
  # carapace/zoxide/starship integrations). Plain `nu -c` only loads the built-in
  # default env — not the user's env.nu or config.nu — so `--login` is required.
  termapp = pkgs.writeScriptBin "termapp" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.ghostty}/bin/ghostty
    fi
    exec ${pkgs.ghostty}/bin/ghostty -e ${pkgs.nushell}/bin/nu --login -c "$*"
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
