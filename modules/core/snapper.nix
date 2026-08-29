{ config, lib, pkgs, ... }:

let
  cfg = config.modules.snapper;
in
{
  options.modules.snapper.enable =
    lib.mkEnableOption "btrfs snapshots via snapper (for / and /home)";

  config = lib.mkIf cfg.enable {
    # Snapper requires a `.snapshots` subvolume inside each snapshotted
    # subvolume, which the nixpkgs module does NOT create for you. Create it
    # idempotently at activation.
    #
    # `/nix` is intentionally NOT snapshotted: Nix generations already provide
    # store rollback, and snapshotting the store wastes space for no benefit.
    #
    # Layout-agnostic: this snapshots by mountpoint, so it works with both the
    # graphical installer's btrfs layout (`home` and `nix` subvolumes, root on
    # the top-level subvolume) and any `@`-prefixed layout. Only `/` and `/home`
    # are snapshotted; `/nix` never is.
    system.activationScripts.snapper-subvols = lib.stringAfter [ "users" ] ''
      for sub in "/" "/home"; do
        if [ ! -e "$sub/.snapshots" ]; then
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$sub/.snapshots"
        fi
      done
    '';

    services.snapper = {
      snapshotRootOnBoot = true;

      configs = {
        root = {
          SUBVOLUME = "/";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "2";
          TIMELINE_LIMIT_MONTHLY = "1";
          TIMELINE_LIMIT_YEARLY = "0";
        };
        home = {
          SUBVOLUME = "/home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "2";
          TIMELINE_LIMIT_MONTHLY = "1";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };
  };
}
