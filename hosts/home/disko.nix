{ ... }:

# Declarative disk layout for the `home` host — btrfs on a single NVMe, inside a
# LUKS container, matching modules/core/snapper.nix (snapshots of `/` and `/home`)
# and systemd-boot (ESP at `/boot`). No on-disk swap: zramSwap handles swap
# (modules/core/hardware.nix).
#
# The root partition is LUKS-encrypted and auto-unlocked by the TPM (with a
# passphrase fallback). Enroll the TPM2 token *after* Secure Boot is enabled
# (PCR 7 reflects the SB state):
#   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 \
#     /dev/disk/by-partlabel/disk-main-luks
# Until then (and on any PCR change) the initrd falls back to the passphrase.
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # `settings` is merged into boot.initrd.luks.devices.<name>
                # (disko generates that entry automatically). No keyFile means
                # disko-install prompts for the passphrase interactively.
                settings = {
                  # NVMe TRIM passthrough.
                  allowDiscards = true;
                  # Auto-unlock via TPM2; falls back to passphrase.
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };
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
  };
}
