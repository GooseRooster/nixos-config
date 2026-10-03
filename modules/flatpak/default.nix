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

    # System-wide "normie" apps (GNOME core, media player, app store).
    # User-facing/opinionated apps are declared per-user in the home-manager
    # repo (modules/flatpak.nix), not here.
    system = {
      enable = lib.mkEnableOption "system-wide baseline Flatpaks";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Flatpak application IDs in the system baseline set.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = lib.optionals cfg.system.enable cfg.system.packages;
  };
}
