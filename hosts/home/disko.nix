{ ... }:

# Declarative disk layout for the `home` host — btrfs on a single NVMe, matching
# modules/core/snapper.nix (snapshots of `/` and `/home`) and systemd-boot (ESP at
# `/boot`). No on-disk swap: zramSwap handles swap (modules/core/hardware.nix).
#
# TODO: replace the `device` with your disk's stable path:
#   lsblk -o PATH,MODEL,SERIAL,SIZE
# e.g. device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_1234567890";
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-REPLACE_ME";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
