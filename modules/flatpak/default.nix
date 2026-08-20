{ config, lib, inputs, ... }:

let
  cfg = config.modules.flatpak;
in
{
  # nixpkgs removed `services.flatpak.packages`; nix-flatpak restores
  # declarative installs (plain strings are coerced to flathub app IDs).
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

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
