{ config, pkgs, lib, ... }:

{
  # UPower and a power-profile daemon are pulled in by the noctalia module's
  # recommendedServices. Only the bluetooth toggle remains here.
  #
  # Default-on for desktops; hosts without BT hardware (e.g. the VM) disable it.
  hardware.bluetooth.enable = lib.mkDefault true;
}
