{ config, lib, ... }:

let
  cfg = config.modules.flatpak;
in
{
  options.modules.flatpak = {
    enable = lib.mkEnableOption "declarative Flatpak management";

    base = {
      enable = lib.mkEnableOption "base Flatpaks";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Flatpak application IDs in the base set.";
      };
    };

    gaming = {
      enable = lib.mkEnableOption "gaming Flatpaks";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Flatpak application IDs in the gaming set.";
      };
    };

    multimedia = {
      enable = lib.mkEnableOption "multimedia Flatpaks";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Flatpak application IDs in the multimedia set.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    services.flatpak.packages =
      lib.concatLists (lib.map (c: lib.optionals c.enable c.packages)
        [ cfg.base cfg.gaming cfg.multimedia ]);
  };
}
