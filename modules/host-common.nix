{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

# Everything shared by the graphical desktop hosts (hosts/home + hosts/laptop).
# Each host imports this plus its own hardware-configuration.nix and a small
# host-specific tail (hostname, LUKS swap UUID, CPU microcode, display output,
# GPU-specific services). Extracting the common 90% keeps the two host files
# honest and pre-stages a future move to a non-NixOS image (the system half
# stays here; the user half rides along in the home-manager repo).
#
# Rationale for what lives here vs. the host file:
#   here       - module imports, the HM user wiring, gaming/theme/power enables,
#                auto-upgrade and secure-boot, session plumbing
#   host file  - hardware identity + hardware-specific services and outputs
{
  imports = [
    ./base.nix
    ./desktop/default.nix
    ./desktop/noctalia.nix
    ./desktop/sway.nix
    ./core/podman.nix
    ./flatpak/system.nix
    ./extras/tuned.nix
    ./gaming/game-performance.nix
    ./gaming/steam.nix
    ./gaming/wine.nix
    ./core/secure-boot.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # ntsync (Wine/Proton): load the module and let desktop users open it.
  boot.kernelModules = [ "ntsync" ];
  services.udev.extraRules = ''
    KERNEL=="ntsync", TAG+="uaccess"
  '';

  modules.users.primary = "gooze";

  # Pin the UID to the account the graphical installer created (first normal
  # user = 1000). Without this, renaming `primary` would silently create a new
  # uid and orphan the existing home + keyring.
  modules.users.uid = 1000;

  # Home dotfiles (the GooseRooster/home-manager repo). hmModules.default
  # bundles home.nix (shared modules + XDG plumbing); the dotfiles repo owns
  # the noctalia settings, flatpak sets and theming tooling. The host sets the
  # feature flags.
  home-manager = {
    # Back up (instead of erroring on) pre-existing files when a foreign
    # standalone generation previously owned overlapping paths.
    backupFileExtension = "hm-backup";

    # The dotfiles repo's per-user flatpak module reads nix-flatpak's
    # home-manager module as a plain function argument.
    extraSpecialArgs = { inherit (inputs) nix-flatpak; };

    users.gooze =
      { osConfig, lib, pkgs, ... }:
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
          inputs.noctalia.homeModules.default
          inputs.zen-browser.homeModules.twilight
        ];

        # HM core now ships its own programs.noctalia module (as the directory
        # modules/programs/noctalia/), whose options collide with the noctalia
        # flake's home module imported above. Disable HM's copy; the noctalia
        # flake's own `disabledModules = [ "programs/noctalia.nix" ]` misses it
        # because HM moved it from that file to a directory.
        disabledModules = [ "programs/noctalia" ];

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

        # Feature flags for the dotfiles modules.
        home.bundles.baseExtra.enable = true; # desktop extras (fonts, vscode, …)
        home.modules.desktop.enable = true; # Sway/Noctalia session configs
        home.modules.gaming.enable = true;
        home.modules.theming.enable = true; # gowall/theme_regen tooling
        home.modules.noctalia.enable = true; # declarative Noctalia settings
        # Rootless podman socket + docker->podman alias (lazydocker/lazypodman).
        home.modules.podmanAlias.enable = true;

        # Per-user Flatpaks (user-facing apps). The system baseline set lives
        # in nixos-config/modules/flatpak/system.nix.
        home.bundles.flatpak.base.enable = true;
        home.bundles.flatpak.multimedia.enable = true;
        home.bundles.flatpak.gaming.enable = true;

        # nvim/yazi ship `Terminal=true` desktop entries (Exec=nvim/yazi).
        # Override them here (these land in ~/.local/share/applications, above
        # the system entries) so they launch through `termapp` instead.
        xdg.desktopEntries = {
          nvim = {
            name = "Neovim";
            genericName = "Text Editor";
            exec = "termapp nvim %F";
            icon = "nvim";
            terminal = false;
            type = "Application";
            categories = [
              "Utility"
              "TextEditor"
              "Development"
            ];
            mimeType = [ "text/plain" ];
          };
          yazi = {
            name = "Yazi File Manager";
            exec = "termapp yazi %f";
            icon = "yazi";
            terminal = false;
            type = "Application";
            categories = [
              "System"
              "FileManager"
              "FileTools"
            ];
            mimeType = [ "text/plain" ];
          };
        };

        # systemd drop-in for the transient unit generated from mini-eq's
        # ~/.config/autostart entry (rationale in miniEqSinkWait above). The
        # directory name carries systemd's escaped form of the unit name.
        xdg.configFile."systemd/user/app-io.github.bhack.mini\\x2deq@autostart.service.d/override.conf".text =
          ''
            [Service]
            ExecStartPre=${miniEqSinkWait}
          '';
      };
  };

  # System baseline Flatpaks + the flatpak daemon.
  modules.flatpak.enable = true;
  modules.flatpak.system.enable = true;

  # Gaming host: 32-bit GL + VA-API/VDPAU extras for Steam/Wine.
  modules.graphics.gaming = true;

  # TuneD power profiles (incl. a custom "gaming" = latency-performance).
  modules.tuned.enable = true;

  # game-performance helper (TuneD profile + Night Light for Steam) on PATH,
  # plus a flatpak-accessible copy in ~/.local/bin.
  modules.gamePerformance.enable = true;

  # Native Steam (Millennium-flavoured) instead of the Flatpak Steam.
  modules.steam.enable = true;

  # Native Wine + winetricks + Faugus Launcher instead of their Flatpaks.
  modules.wine.enable = true;

  # Firefox Developer Edition alongside regular Firefox for web dev work.
  # Dev Edition keeps its own dedicated profile directory, so the two
  # browsers never touch each other's state.
  environment.systemPackages = [ pkgs.firefox-devedition ];

  # Stage weekly upgrades in the bootloader (no live switch); reboot to apply.
  modules.autoUpgrade.enable = true;
  modules.autoUpgrade.flake = "github:GooseRooster/nixos-config#home";

  modules.secureBoot.enable = true;
}
