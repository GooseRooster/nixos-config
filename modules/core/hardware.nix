{ config, lib, pkgs, ... }:

# Cross-host hardware "batteries" — firmware, CPU microcode, memory.
{
  # Firmware blobs (Wi-Fi/Bluetooth/GPU/audio). Includes the nonfree
  # linux-firmware set, so requires `nixpkgs.config.allowUnfree = true`
  # (already set in modules/core/nix.nix). Harmless in VMs.
  hardware.enableAllFirmware = true;

  # AMD CPU microcode updates (e.g. Ryzen 7800X3D). If a host is Intel, set
  # `hardware.cpu.intel.updateMicrocode = true` there instead.
  hardware.cpu.amd.updateMicrocode = true;

  # Compressed RAM swap (Bluefin-style). Sits above any on-disk swap partition
  # and gives much lower-latency swapping. Sizing inspired by CachyOS: full RAM,
  # zstd, and swap-priority 100 so zram is always preferred over disk swap.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
  zramSwap.priority = 100;
}
