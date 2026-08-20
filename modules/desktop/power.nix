{ config, pkgs, lib, ... }:

{
  # power-profiles-daemon and upower are already enabled by GNOME's
  # core-os-services. Only the bluetooth toggle remains here.
  #
  # Default-on for desktops; hosts without BT hardware (e.g. the VM) disable it.
  hardware.bluetooth.enable = lib.mkDefault true;
}
