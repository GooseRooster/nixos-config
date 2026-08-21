{ pkgs, ... }:

# Declarative GNOME dconf defaults (system-db sits below user-db, so these are
# soft defaults the user can still override in Settings).
{
  programs.dconf.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          # JetBrains Mono only as the monospace/terminal default — Nerd Fonts
          # are awkward to get Flatpaks to respect as a UI font.
          monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
        };

        # Legacy default-terminal key — still used by the gsd media-key /
        # GNOME Shell "New Terminal" action. `Terminal=true` .desktop entries
        # are handled by xdg.terminal-exec (see terminal.nix).
        "org/gnome/desktop/default-applications/terminal" = {
          exec = "ghostty";
          exec-arg = "-e";
        };

        # Enable the user-themes extension so Refine's shell-theme row works.
        "org/gnome/shell" = {
          enabled-extensions = [
            pkgs.gnomeExtensions.user-themes.extensionUuid
          ];
        };
      };
    }
  ];
}
