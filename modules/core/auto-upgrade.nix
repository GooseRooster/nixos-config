{ config, lib, pkgs, ... }:

let
  cfg = config.modules.autoUpgrade;
in
{
  options.modules.autoUpgrade = {
    enable = lib.mkEnableOption "automatic system upgrades on a timer";

    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Flake URI this host upgrades from, e.g.
          "git+file:///home/gooze/.config/nixos-config#home"   (local repo)
          "github:GooseRooster/nixos-config#home"              (pushed repo)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.flake != null;
        message = "modules.autoUpgrade.flake must be set when auto-upgrade is enabled.";
      }
    ];

    system.autoUpgrade = {
      enable = true;

      # `boot` stages the new system in the bootloader WITHOUT switching —
      # the running session is never touched. You reboot at your convenience
      # to activate it. (The default `switch` would hot-swap and can kill a
      # running session.)
      operation = "boot";

      dates = "weekly";

      flake = cfg.flake;

      # No surprise reboots. To auto-reboot within a window instead, set
      # `allowReboot = true;` plus a `rebootWindow = { lower = "..."; upper = "..."; }`.
      allowReboot = false;
    };
  };
}
