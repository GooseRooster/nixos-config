{ config, lib, ... }:

let
  cfg = config.modules.maintenance;
in
{
  options.modules.maintenance.enable =
    lib.mkEnableOption "automatic nix GC, store optimisation and firmware updates";

  config = lib.mkIf cfg.enable {
    # Garbage-collect old generations weekly; 14 days of rollback window,
    # further capped by the bootloader generation limit.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
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
