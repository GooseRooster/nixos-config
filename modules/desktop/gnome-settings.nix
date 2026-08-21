{ pkgs, ... }:

# Declarative GNOME dconf defaults (system-db sits below user-db, so these are
# soft defaults the user can still override in Settings; GDM has no user db, so
# its font is effectively forced).
let
  font = "JetBrainsMono Nerd Font Mono 11";
in
{
  programs.dconf.enable = true;

  # GNOME session defaults.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          font-name = font;
          document-font-name = font;
          monospace-font-name = font;
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

  # GDM login screen (gdm user profile) uses the same fonts.
  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          font-name = font;
          document-font-name = font;
          monospace-font-name = font;
        };
      };
    }
  ];
}
