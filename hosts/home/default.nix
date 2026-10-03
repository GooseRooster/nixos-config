{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

# Desktop/workstation host. Shared system + user config lives in
# modules/host-common.nix; this file carries hardware identity and the
# desktop-specific GPU/display bits.
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host-common.nix
  ];

  networking.hostName = "nixos";

  hardware.cpu.amd.updateMicrocode = true;

  # The graphical installer created an encrypted swap partition (separate from
  # the root LUKS container). Its unlock entry is written to the installer's
  # configuration.nix (not hardware-configuration.nix), so carry it over here.
  boot.initrd.luks.devices."luks-cef99b37-a347-4432-be60-8d04312cf661".device =
    "/dev/disk/by-uuid/cef99b37-a347-4432-be60-8d04312cf661";

  # LACT (GPU monitoring/overclocking) native with its system daemon; the GUI
  # manages /etc/lact/config.yaml itself (left unmanaged so the GUI can write).
  # AMD GPU: overdrive unlocks the OC/underclock controls in LACT.
  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  # This host's display: Dell AW3423DWF QD-OLED ultrawide. VRR while
  # fullscreen, HDR auto-activates on fullscreen surfaces with HDR
  # metadata. HDR10 needs the Vulkan renderer (set in modules/desktop/
  # sway.nix). The Sway config itself lives in the dotfiles sway module.
  home-manager.users.gooze.home.modules.sway.extraConfig = ''
    output DP-3 mode 3440x1440@164.9Hz
    output DP-3 adaptive_sync on
    output DP-3 hdr on
  '';

  system.stateVersion = "26.05";
}
