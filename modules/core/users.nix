{ config, lib, ... }:

let
  cfg = config.modules.users;
in
{
  options.modules.users = {
    primary = lib.mkOption {
      type = lib.types.str;
      default = "gooze";
      description = "Primary normal user account name.";
    };

    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Explicit UID for the primary user. Pin this so a rename never silently
        creates a second account (uid drift) and orphans the existing home and
        keyring. Leave null to let NixOS auto-assign the next free uid.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups for the primary user.";
    };

    initialPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Initial password for the primary user. Only applied while the account
        has no password set (so `passwd` can change it later). Leave null to
        set the password imperatively after first boot.
      '';
    };
  };

  config = {
    users.users.${cfg.primary} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
    }
    // lib.optionalAttrs (cfg.uid != null) {
      uid = cfg.uid;
    }
    // lib.optionalAttrs (cfg.initialPassword != null) {
      initialPassword = cfg.initialPassword;
    };
  };
}
