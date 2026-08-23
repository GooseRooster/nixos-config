{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.secureBoot;
in
{
  # Import unconditionally: the lanzaboote module only defines options and is
  # inert until boot.lanzaboote.enable is set. Gating the import would be a
  # NixOS anti-pattern (imports can't be mkIf'd safely).
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.modules.secureBoot.enable =
    lib.mkEnableOption "Secure Boot via Lanzaboote (requires sbctl keys)";

  config = lib.mkIf cfg.enable {
    # For debugging/troubleshooting Secure Boot.
    environment.systemPackages = [ pkgs.sbctl ];

    # Lanzaboote installs its own boot entries and signs kernels/initrds as
    # UKIs; it replaces the systemd-boot module.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      # sbctl stores the Secure Boot keys here (`sbctl create-keys`).
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
