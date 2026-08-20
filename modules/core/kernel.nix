{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.kernel;
in
{
  options.modules.kernel = {
    variant = lib.mkOption {
      type = lib.types.enum [ "cachyos" "latest" "lts" ];
      default = "cachyos";
      description = "Which kernel family to use. Select per-host/per-flavor.";
    };

    cachyosFlavor = lib.mkOption {
      type = lib.types.str;
      default = "linuxPackages-cachyos-latest";
      description = ''
        CachyOS kernel variant (attribute under pkgs.cachyosKernels).
        Default is x86_64-v1 so it runs anywhere (e.g. VMs). Hosts on newer
        CPUs should opt into an arch-tuned build, e.g.:
          linuxPackages-cachyos-latest-zen4     (AMD Zen 4/5)
          linuxPackages-cachyos-latest-x86_64-v3
          linuxPackages-cachyos-latest-x86_64-v4
        The -lto-* variants use Clang ThinLTO but can break out-of-tree modules.
      '';
    };
  };

  config = {
    # Expose pkgs.cachyosKernels.*. `pinned` uses the exact nixpkgs revision
    # the kernels were built against, guaranteeing binary cache hits.
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

    boot.kernelPackages =
      if cfg.variant == "cachyos" then pkgs.cachyosKernels.${cfg.cachyosFlavor}
      else if cfg.variant == "latest" then pkgs.linuxPackages_latest
      else pkgs.linuxPackages; # lts
  };
}
