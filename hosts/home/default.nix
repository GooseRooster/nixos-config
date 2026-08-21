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
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  modules.users.primary = "gooze";

  # Home dotfiles (the GooseRooster/home-manager repo). Flags mirror the
  # system-side flatpak/theming toggles below.
  home-manager.users.gooze = {
    imports = [ inputs.dotfiles.hmModules.default ];
    home.modules.gaming.enable = true;
    home.modules.theming.enable = true;
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

  # btrfs snapshots of / and /home (rollback for data, unlike Nix generations).
  modules.snapper.enable = true;

  # CachyOS kernel tuned for this host's AMD Ryzen 7 7800X3D (Zen 4).
  modules.kernel.cachyosFlavor = "linuxPackages-cachyos-latest-zen4";

  # Stage weekly upgrades in the bootloader (no live switch); reboot to apply.
  modules.autoUpgrade.enable = true;
  modules.autoUpgrade.flake = "github:GooseRooster/nixos-config#home";

  system.stateVersion = "26.05";
}
