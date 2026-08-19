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

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups for the primary user.";
    };
  };

  config = {
    # No password is declared: with users.mutableUsers = true (default) you set
    # it imperatively after first boot with `sudo passwd <user>`.
    users.users.${cfg.primary} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
    };
  };
}
