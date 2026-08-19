{ config, pkgs, lib, ... }:

{
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Noctalia's bluetooth widget needs this. Default-on for desktops; hosts
  # without BT hardware (e.g. the VM) disable it.
  hardware.bluetooth.enable = lib.mkDefault true;
}
