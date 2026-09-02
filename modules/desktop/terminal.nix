{ config, lib, pkgs, ... }:

let
  # The dotfiles' default-shell flag (home-manager repo, modules/flavors.nix).
  # Set as a plain per-host value there, so reading it back here can't create
  # an eval cycle; `or "nu"` covers hosts that don't wire home-manager at all.
  hmShell =
    (config.home-manager.users.${config.modules.users.primary}.home.modules.defaultShell or "nu");

  # Launch a terminal app in Ghostty with the default shell's environment
  # bootstrapped. Ghostty's `-e` sets initial-command, which replaces the
  # `command = <shell>` setting, so a bare `ghostty -e nvim` skips shell init
  # entirely. Wrapping the command in the shell restores the full startup:
  # - nu --login -c: sources env.nu + config.nu ($EDITOR/$NVIM_PROFILE/
  #   $SSH_AUTH_SOCK, config.nu aliases/functions like `y`, the
  #   carapace/zoxide/starship integrations). Plain `nu -c` only loads the
  #   built-in default env — not the user's env.nu or config.nu — so
  #   `--login` is required.
  # - zsh -l -c: login env only. .zshrc is interactive-only, so shell
  #   aliases/functions aren't loaded — fine for binary targets (nvim, yazi).
  termapp = pkgs.writeScriptBin "termapp" ''
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.ghostty}/bin/ghostty
    fi
    exec ${pkgs.ghostty}/bin/ghostty -e ${
      if hmShell == "zsh"
      then "${pkgs.zsh}/bin/zsh -l -c"
      else "${pkgs.nushell}/bin/nu --login -c"
    } "$*"
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
