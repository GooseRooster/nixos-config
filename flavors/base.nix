{ lib, ... }:

{
  imports = [
    ../modules/core/system.nix
    ../modules/core/hardware.nix
    ../modules/core/kernel.nix
    ../modules/core/perf.nix
    ../modules/core/nix.nix
    ../modules/core/users.nix
    ../modules/core/hardening.nix
    ../modules/core/maintenance.nix
    ../modules/core/gnupg.nix
    ../modules/core/auto-upgrade.nix
    ../modules/core/snapper.nix
  ];

  modules.perf.enable = true;
  modules.hardening.enable = true;
  modules.maintenance.enable = true;

  # Base groups every host gets; desktop/headless flavors may override.
  modules.users.extraGroups = lib.mkDefault [ "wheel" "networkmanager" ];
}
