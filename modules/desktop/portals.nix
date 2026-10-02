{ config, pkgs, lib, ... }:

{
  # nixpkgs' Sway module wires up xdg.portal and the wlr/gtk backends; the
  # noctalia and sway modules add the extra portal backends they need. This
  # just makes the portal service explicit.
  xdg.portal.enable = true;
}
