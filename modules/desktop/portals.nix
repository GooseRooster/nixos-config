{ config, pkgs, lib, ... }:

{
  # Base portal service. The scroll module already sets xdg.portal.config.scroll
  # (default=gtk, ScreenCast/Screenshot=wlr), so we only install the backends.
  xdg.portal.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
  ];
}
