{ lib, ... }:

# Shared base every host imports: core system plumbing + the enable defaults
# for the toggleable core modules. Host-specific extras (desktop stacks, cli
# bundles, podman, flatpak sets, ...) are imported by hosts directly.
{
  imports = [
    ./core/system.nix
    ./core/hardware.nix
    ./core/kernel.nix
    ./core/perf.nix
    ./core/nix.nix
    ./core/users.nix
    ./core/hardening.nix
    ./core/maintenance.nix
    ./core/gnupg.nix
    ./core/auto-upgrade.nix
    ./core/snapper.nix
  ];

  modules.perf.enable = true;
  modules.hardening.enable = true;
  modules.maintenance.enable = true;

  # Base groups every host gets; hosts override with their own list.
  modules.users.extraGroups = lib.mkDefault [ "wheel" "networkmanager" ];
}
