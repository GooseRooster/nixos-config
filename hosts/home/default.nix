{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../flavors/desktop.nix
    ../../modules/flatpak/base.nix
    ../../modules/flatpak/gaming.nix
    ../../modules/flatpak/multimedia.nix
    ../../modules/extras/theming.nix
    ../../modules/extras/tuned.nix
    ../../modules/gaming/game-performance.nix
    ../../modules/gaming/steam.nix
    ../../modules/gaming/wine.nix
    ../../modules/core/secure-boot.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  # The graphical installer created an encrypted swap partition (separate from
  # the root LUKS container). Its unlock entry is written to the installer's
  # configuration.nix (not hardware-configuration.nix), so carry it over here.
  boot.initrd.luks.devices."luks-cef99b37-a347-4432-be60-8d04312cf661".device =
    "/dev/disk/by-uuid/cef99b37-a347-4432-be60-8d04312cf661";

  modules.users.primary = "gooze";

  # Pin the UID to the account the graphical installer created (first normal
  # user = 1000). Without this, renaming `primary` would silently create a new
  # uid and orphan the existing home + keyring.
  modules.users.uid = 1000;

  # Home dotfiles (the GooseRooster/home-manager repo). hmModules.desktop
  # bundles home.nix + hosts/desktop.nix, which sets the gaming/theming/
  # podmanAlias flags and the session below is mirrored into it — the
  # standalone (`home-manager switch`) and integrated tracks stay identical.
  home-manager = {
    # Back up (instead of erroring on) pre-existing files when the standalone
    # and integrated HM generations trade ownership of overlapping paths.
    backupFileExtension = "hm-backup";

    users.gooze =
      { osConfig, lib, ... }:
      {
        imports = [
          inputs.dotfiles.hmModules.desktop
          inputs.noctalia.homeModules.default
          inputs.umbriel.homeModules.default
        ];

        # Mirror the NixOS session choice into the dotfiles flags so
        # session-gated HM content (tinty -> Noctalia hook) follows the
        # modules.desktop.session option.
        home.modules.session = osConfig.modules.desktop.session;

      # nvim/yazi ship `Terminal=true` desktop entries (Exec=nvim/yazi). Override
      # them here (these land in ~/.local/share/applications, above the system
      # entries) so they launch through `termapp` instead: ghostty + a bootstrapped
      # nushell env, not a bare terminal command that skips env.nu.
      xdg.desktopEntries = {
        nvim = {
          name = "Neovim";
          genericName = "Text Editor";
          exec = "termapp nvim %F";
          icon = "nvim";
          terminal = false;
          type = "Application";
          categories = [ "Utility" "TextEditor" "Development" ];
          mimeType = [ "text/plain" ];
        };
        yazi = {
          name = "Yazi File Manager";
          exec = "termapp yazi %f";
          icon = "yazi";
          terminal = false;
          type = "Application";
          categories = [ "System" "FileManager" "FileTools" ];
          mimeType = [ "inode/directory" ];
        };
      };

      # Noctalia v5 + Umbriel baseline settings (both are build-validated by
      # their packages). Only materialised when the noctalia session stack is
      # active — with GNOME selected these stay absent so the config files
      # aren't generated for shells that aren't running.
      programs.noctalia = lib.mkIf (osConfig.modules.desktop.session == "noctalia") {
        # The shell itself is autostarted by Umbriel ([general].autostart
        # below); enable here just installs the config file.
        enable = true;
        settings = {
          shell = {
            # Noctalia's native polkit agent (security.polkit is enabled by
            # the noctalia NixOS module).
            polkit_agent = true;

            # Screenshot output policy for screenshot-region/-fullscreen IPC
            # (bound to Umbriel keybinds below).
            screenshot = {
              directory = "~/Pictures/Screenshots";
              save_to_file = true;
              copy_to_clipboard = true;
            };
          };

          # Lockscreen/notification daemons are built into Noctalia.
          lockscreen.enabled = true;
        };
      };

      programs.umbriel = lib.mkIf (osConfig.modules.desktop.session == "noctalia") {
        enable = true;
        settings = {
          # Layer our overrides on top of Umbriel's packaged default config
          # (main-file values win over every include).
          include.files = [
            "${osConfig.programs.umbriel.package}/share/umbriel/config.toml"
          ];

          # Auto-start the Noctalia shell with the compositor.
          general.autostart = [ "noctalia" ];

          # This host's display: Dell AW3423DWF QD-OLED ultrawide. VRR while
          # fullscreen, HDR auto-activates on fullscreen surfaces with HDR metadata.
          output."DP-3" = {
            mode = "3440x1440@164.9";
            hdr = "auto";
            vrr = "fullscreen";
          };

          # PaperWM-style muscle memory on Umbriel's scrolling layout, plus the
          # Noctalia IPC integration (docs.noctalia.dev). Overrides of the
          # packaged defaults win over the included base config.
          keybinds = {
            # Terminal + window management.
            "Mod+Return" = "spawn:termapp";
            "Mod+Q" = "window-close";

            # yazi file manager 
            "Mod+E" = "spawn:termapp yazi";
              

            # Screenshots (Noctalia's built-in capture over wlr-screencopy).
            "Print" = "spawn:noctalia msg screenshot-region";
            "Mod+Print" = "spawn:noctalia msg screenshot-fullscreen";

            # PaperWM immerse/expel: merge the focused window into the column
            # to its left / push it out into its own new column. True float
            # <-> tile stays on the packaged Mod+T (window-toggle-floating).
            "Mod+I" = "window-consume-left";
            "Mod+O" = "window-expel-right";
            "Mod+Tab" = "overview-toggle";

            # Column width: toggle full width <-> previous width, and nudge
            # the width in 5% steps (clamped 0.1-1.0). Mod+Equal covers the
            # unshifted + key; Mod+Plus the shifted one.
            "Mod+F" = "window-toggle-maximize";
            "Mod+Equal" = "window-modify-width:0.05";
            "Mod+Plus" = "window-modify-width:0.05";
            "Mod+Minus" = "window-modify-width:-0.05";

            # Focus (vim directions).
            "Mod+H" = "window-focus-left";
            "Mod+J" = "window-focus-down";
            "Mod+K" = "window-focus-up";
            "Mod+L" = "window-focus-right";

            # Move window/column within the layout.
            "Mod+Ctrl+H" = "column-move-left";
            "Mod+Ctrl+J" = "window-move-down";
            "Mod+Ctrl+K" = "window-move-up";
            "Mod+Ctrl+L" = "column-move-right";

            # Move window across workspaces (linear per output: prev/next;
            # J/K move within the column or across the workspace boundary).
            "Mod+Shift+H" = "window-move-to-workspace-previous";
            "Mod+Shift+J" = "window-move-or-workspace-down";
            "Mod+Shift+K" = "window-move-or-workspace-up";
            "Mod+Shift+L" = "window-move-to-workspace-next";

            # Switch workspaces.
            "Mod+Alt+K" = "workspace-previous";
            "Mod+Alt+J" = "workspace-next";

            # Noctalia panels; lock moved here (Mod+Shift+L is taken above).
            "Mod+V" = "spawn:noctalia msg panel-toggle clipboard";
            "Mod+W" = "spawn:noctalia msg panel-toggle wallpaper";
            "Mod+X" = "spawn:noctalia msg bar-toggle";
            "Mod+Escape" = "spawn:noctalia msg panel-toggle session";
            "Ctrl+Alt+L" = "spawn:noctalia msg session lock";

            "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
            "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
            "Mod+XF86AudioMute" = "spawn:wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86MonBrightnessUp" = {
              action = "spawn:noctalia msg brightness-up 10";
              allow_when_locked = true;
            };
            "XF86MonBrightnessDown" = {
              action = "spawn:noctalia msg brightness-down 10";
              allow_when_locked = true;
            };
          };
        };
      };
    };
  };

  modules.flatpak.enable = true;
  modules.flatpak.base.enable = true;
  modules.flatpak.gaming.enable = true;
  modules.flatpak.multimedia.enable = true;

  modules.theming.enable = true;

  # Gaming host: 32-bit GL + VA-API/VDPAU extras for Steam/Wine.
  modules.graphics.gaming = true;

  # TuneD power profiles (incl. a custom "gaming" = latency-performance).
  modules.tuned.enable = true;

  # game-performance helper (TuneD profile + Night Light for Steam) on PATH,
  # plus a flatpak-accessible copy in ~/.local/bin.
  modules.gamePerformance.enable = true;

  # btrfs snapshots of / and /home (rollback for data, unlike Nix generations).
  modules.snapper.enable = true;

  # Lightweight DE: ly (DM) + Umbriel (compositor) + Noctalia v5 (shell).
  # Flip back to "gnome" (the flavor default) to return to GDM + GNOME.
  modules.desktop.session = "noctalia";

  # Native Steam (Millennium-flavoured) instead of the Flatpak Steam.
  modules.steam.enable = true;

  # Native Wine + winetricks + Faugus Launcher instead of their Flatpaks.
  modules.wine.enable = true;

  # Stage weekly upgrades in the bootloader (no live switch); reboot to apply.
  modules.autoUpgrade.enable = true;
  modules.autoUpgrade.flake = "github:GooseRooster/nixos-config#home";

  modules.secureBoot.enable = true;

  system.stateVersion = "26.05";
}
