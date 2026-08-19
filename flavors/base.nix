{ ... }:

{
  imports = [
    ../modules/core/system.nix
    ../modules/core/kernel.nix
    ../modules/core/perf.nix
    ../modules/core/nix.nix
  ];

  modules.perf.enable = true;
}
