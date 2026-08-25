{ config, pkgs, lib, ... }:

# Minimal core that every flavor shares.
{
  time.timeZone = "Africa/Johannesburg";

  # British English locale, US English keyboard.
  i18n.defaultLocale = "en_GB.UTF-8";
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";

  # systemd stage-1 (default on modern NixOS, but explicit): required for
  # TPM2-based LUKS auto-unlock and for hibernation resume, if enabled later.
  boot.initrd.systemd.enable = true;

  # TPM2 resource manager + udev rules. Needed for systemd-cryptenroll (LUKS
  # TPM2 enrollment) and harmless where no TPM exists (e.g. the VM).
  security.tpm2.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    openssh
    ppp # pppd, for legacy Fortinet/PPTP VPNs
    sbctl
    libnotify
    wl-clipboard
  ];
}
