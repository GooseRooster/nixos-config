{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop/default.nix
    ../../modules/desktop/gnome.nix
    ../../modules/desktop/gnome-devtools.nix
    ../../modules/desktop/gnome-settings.nix
    ../../modules/desktop/gnome-extensions.nix
    ../../modules/core/podman.nix
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

  # Home dotfiles (the GooseRooster/home-manager repo). hmModules.default
  # bundles home.nix (shared modules + XDG plumbing); this host sets the
  # home.modules.* feature flags itself.
  home-manager = {
    # Back up (instead of erroring on) pre-existing files when a foreign
    # standalone generation previously owned overlapping paths.
    backupFileExtension = "hm-backup";

    users.gooze =
      { lib, pkgs, ... }:
      let
        # Mini EQ autostart is a startup race: the Background portal
        # (xdg-desktop-portal-gnome) drops
        # ~/.config/autostart/io.github.bhack.mini-eq.desktop, GNOME's systemd
        # user session turns that into a transient app-*@autostart.service unit
        # (systemd-xdg-autostart-generator), and the unit starts with the
        # session — i.e. before wireplumber has published the default sink.
        # mini-eq's --auto-route then errors ("output sink cannot be a Mini EQ
        # virtual sink") and exits. Drop-ins also apply to generator-produced
        # units, so gate the (unchanged) ExecStart on a real default sink below.
        miniEqSinkWait = pkgs.writeShellScript "mini-eq-wait-default-sink" ''
          # Wait (max 60s) until pactl reports a default sink that is NOT Mini
          # EQ's own virtual filter-chain (mini_eq_sink), then let ExecStart
          # run. On timeout, start anyway and let mini-eq fail loudly. Match
          # on mini+eq, not just "mini" — the RØDE NT-USB Mini is a real sink.
          pactl="${lib.getExe' pkgs.pulseaudio "pactl"}"
          for _ in $(seq 1 60); do
            sink="$("$pactl" info 2>/dev/null | sed -n 's/^Default Sink: //p' || true)"
            lower="''${sink,,}"
            if [[ -n "$lower" && "$lower" != *mini*eq* && "$lower" != *eq*mini* ]]; then
              exit 0
            fi
            sleep 1
          done
        '';
      in
      {
      imports = [
        inputs.dotfiles.hmModules.default
        inputs.zen-browser.homeModules.twilight
      ];

      # Zen Browser, native (browser sandboxes behave better native than
      # flatpak). Default browser; Firefox stays installed as the backup.
      # Launch as `zen-twilight`.
      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;

        # Light de-bloat; keep Zen's own update checker disabled since the
        # flake manages versions (twilight artifacts are pinned in flake.lock).
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DontCheckDefaultBrowser = true;
          DisableAppUpdate = true;
        };
      };

        # Feature flags for the dotfiles modules (formerly hosts/desktop.nix
        # in the dotfiles repo, which no longer carries per-host files).
        home.bundles.baseExtra.enable = true; # desktop extras (fonts, vscode, …)
        home.modules.gaming.enable = true;
        home.modules.theming.enable = true;
        # Rootless podman socket + docker->podman alias (lazydocker/lazypodman).
        home.modules.podmanAlias.enable = true;

        # zsh as the default interactive shell. Drives the dotfiles' ghostty
        # `command` and (via modules/desktop/terminal.nix reading this same
        # flag back) the termapp wrapper.
        home.modules.defaultShell = "zsh";

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
          mimeType = [ "text/plain" ];
        };
      };

      # systemd drop-in for the transient unit generated from mini-eq's
      # ~/.config/autostart entry (rationale in miniEqSinkWait above). The
      # directory name carries systemd's escaped form of the unit name.
      xdg.configFile."systemd/user/app-io.github.bhack.mini\\x2deq@autostart.service.d/override.conf".text = ''
        [Service]
        ExecStartPre=${miniEqSinkWait}
      '';
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

  # GNOME (GDM + GNOME Shell) with tinty + gnomad owning theming
  # (modules/extras/theming.nix).

  # Native Steam (Millennium-flavoured) instead of the Flatpak Steam.
  modules.steam.enable = true;

  # Native Wine + winetricks + Faugus Launcher instead of their Flatpaks.
  modules.wine.enable = true;

  # LACT (GPU monitoring/overclocking) native with its system daemon; the GUI
  # manages /etc/lact/config.yaml itself (left unmanaged so the GUI can write).
  # AMD GPU: overdrive unlocks the OC/underclock controls in LACT.
  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  # Firefox Developer Edition alongside regular Firefox for web dev work.
  # Dev Edition keeps its own dedicated profile directory, so the two
  # browsers never touch each other's state.
  environment.systemPackages = [ pkgs.firefox-devedition ];

  # Stage weekly upgrades in the bootloader (no live switch); reboot to apply.
  modules.autoUpgrade.enable = true;
  modules.autoUpgrade.flake = "github:GooseRooster/nixos-config#home";

  modules.secureBoot.enable = true;

  system.stateVersion = "26.05";
}
