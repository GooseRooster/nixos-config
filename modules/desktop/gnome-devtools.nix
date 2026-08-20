{ config, lib, pkgs, ... }:

{
  # GNOME core developer tools that have no Flatpak equivalent.
  # (gnome-builder + dconf-editor are installed as Flatpaks instead.)
  services.sysprof.enable = true; # system-wide profiler daemon

  environment.systemPackages = with pkgs; [
    devhelp   # API documentation browser
    d-spy     # D-Bus inspector
    sysprof   # system/kernel profiler
  ];
}
