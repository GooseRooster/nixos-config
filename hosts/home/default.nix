{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../flavors/desktop.nix
    ../../modules/flatpak/base.nix
    ../../modules/flatpak/gaming.nix
    ../../modules/flatpak/multimedia.nix
    ../../modules/extras/theming.nix
  ];

  # TODO: confirm the hostname for this machine.
  networking.hostName = "bluefin";

  modules.users.primary = "gooze";

  modules.flatpak.enable = true;
  modules.flatpak.base.enable = true;
  modules.flatpak.gaming.enable = true;
  modules.flatpak.multimedia.enable = true;

  modules.theming.enable = true;

  # CachyOS kernel tuned for this host's AMD Ryzen 7 7800X3D (Zen 4).
  modules.kernel.cachyosFlavor = "linuxPackages-cachyos-latest-zen4";

  system.stateVersion = "26.05";
}
