{ config, lib, pkgs, ... }:

let
  cfg = config.modules.kernel;
in
{
  options.modules.kernel = {
    variant = lib.mkOption {
      type = lib.types.enum [ "latest" "lts" ];
      default = "latest";
      description = "Which nixpkgs kernel family to use. Select per-host/per-flavor.";
    };
  };

  config = {
    boot.kernelPackages =
      if cfg.variant == "latest" then pkgs.linuxPackages_latest
      else pkgs.linuxPackages; # lts
  };
}
