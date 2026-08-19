{ config, pkgs, lib, ... }:

# Minimal core that every flavor shares.
{
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_GB.UTF-8";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # QEMU/Spice guest integration (this is a VM).
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    openssh
  ];
}
