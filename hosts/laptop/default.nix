{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

# Laptop host. Shared system + user config lives in modules/host-common.nix;
# this file carries hardware identity only. The internal panel is left to
# Sway's auto-detected output config (no per-host output block).
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host-common.nix
  ];

  networking.hostName = "nixos";

  hardware.cpu.intel.updateMicrocode = true;

  # The graphical installer created an encrypted swap partition (separate from
  # the root LUKS container). Its unlock entry is written to the installer's
  # configuration.nix (not hardware-configuration.nix), so carry it over here.
  boot.initrd.luks.devices."luks-dffd0ff3-06ef-4b5e-866f-1c12388a477c".device =
    "/dev/disk/by-uuid/dffd0ff3-06ef-4b5e-866f-1c12388a477c";

  system.stateVersion = "26.05";
}
