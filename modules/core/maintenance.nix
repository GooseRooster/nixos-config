{ config, lib, ... }:

let
  cfg = config.modules.maintenance;
in
{
  options.modules.maintenance.enable =
    lib.mkEnableOption "automatic nix GC, store optimisation and firmware updates";

  config = lib.mkIf cfg.enable {
    # Garbage-collect old generations weekly, keep 30 days for rollback safety.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Deduplicate/hardlink identical store paths.
    nix.optimise.automatic = true;

    # Firmware updates via LVFS (fwupdmgr). NOTE: also available as the
    # org.gnome.Firmware flatpak — this is the underlying daemon it drives.
    services.fwupd.enable = true;

    # Monthly btrfs scrub (no-op on non-btrfs filesystems).
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
    };
  };
}
