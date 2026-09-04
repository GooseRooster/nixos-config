{ lib, pkgs, ... }:

# Shared base every host imports: core system plumbing + the enable defaults
# for the toggleable core modules. Host-specific extras (desktop stacks, podman,
# flatpak sets, ...) are imported by hosts directly; CLI batteries come via the
# home-manager repo's home.bundles.* options.
{
  imports = [
    ./core/system.nix
    ./core/hardware.nix
    ./core/kernel.nix
    ./core/perf.nix
    ./core/nix.nix
    ./core/users.nix
    ./core/ssh.nix
    ./core/hardening.nix
    ./core/maintenance.nix
    ./core/gnupg.nix
    ./core/auto-upgrade.nix
    ./core/snapper.nix
  ];

  modules.perf.enable = true;
  modules.hardening.enable = true;
  modules.maintenance.enable = true;

  # Escape hatch for prebuilt dynamically-linked (glibc) binaries — NixOS
  # otherwise ships a stub /lib64/ld-linux-x86-64.so.2 and they die with
  # "libstdc++.so.6 => not found". Needed for certain stacks' LSPs (Rust, Dotnet)
  # # NOTE: any future prebuilt binary may need extra libs appended here.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];

  # Base groups every host gets; hosts override with their own list.
  modules.users.extraGroups = lib.mkDefault [ "wheel" "networkmanager" ];
}
