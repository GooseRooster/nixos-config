{ config, pkgs, lib, ... }:

{
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Noctalia's bluetooth widget needs this (no BT hardware in this VM):
  # hardware.bluetooth.enable = true;
}
