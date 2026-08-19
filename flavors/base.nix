{ lib, ... }:

{
  imports = [
    ../modules/core/system.nix
    ../modules/core/kernel.nix
    ../modules/core/perf.nix
    ../modules/core/nix.nix
    ../modules/core/users.nix
  ];

  modules.perf.enable = true;

  # Base groups every host gets; desktop/headless flavors may override.
  modules.users.extraGroups = lib.mkDefault [ "wheel" "networkmanager" ];
}
