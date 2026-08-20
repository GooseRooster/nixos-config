{ config, pkgs, lib, ... }:

{
  # GNOME's core-os-services already enables xdg.portal and installs
  # xdg-desktop-portal-gnome + xdg-desktop-portal-gtk plus the portal config.
  # This just makes the portal service explicit.
  xdg.portal.enable = true;
}
