{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../flavors/desktop.nix
  ];

  networking.hostName = "nixos";

  # Users are managed imperatively (adduser/usermod), not declared here.
  # Required supplementary groups for a desktop user:
  #   sudo usermod -aG wheel,networkmanager,video,render,input,audio <user>

  system.stateVersion = "26.05";
}
