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

  # The graphical installer created an encrypted swap partition (separate from
  # the root LUKS container). Its unlock entry is written to the installer's
  # configuration.nix (not hardware-configuration.nix), so carry it over here.
  boot.initrd.luks.devices."luks-cef99b37-a347-4432-be60-8d04312cf661".device =
    "/dev/disk/by-uuid/cef99b37-a347-4432-be60-8d04312cf661";

  modules.users.primary = "goose";

  # A declarative user, separate from the throwaway account created during the
  # graphical install. `initialPassword` only applies while the account has no
  # password set, so `passwd goose` can replace it after first boot.
  modules.users.initialPassword = "changeme";

  # Home dotfiles (the GooseRooster/home-manager repo). Flags mirror the
  # system-side flatpak/theming toggles below.
  home-manager.users.goose = {
    imports = [ inputs.dotfiles.hmModules.default ];
    home.modules.gaming.enable = true;
    home.modules.theming.enable = true;
    home.modules.podmanAlias.enable = true;
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
