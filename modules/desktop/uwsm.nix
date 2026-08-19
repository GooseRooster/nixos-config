{ config, lib, pkgs, ... }:

{
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      scroll = {
        prettyName = "Scroll";
        comment = "Scroll compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/scroll";
      };
    };
  };

  # UWSM uses dbus-broker; nothing else to do here. Note: scroll is a sway
  # fork but UWSM has no `scroll` plugin. The sway plugin's extra vars
  # (SWAYSOCK/I3SOCK) are handled by the scroll module's nixos.conf instead.
  # If you need sway-plugin behaviour, add to ~/.config/uwsm/env-scroll
  # (chezmoi):
  #   export UWSM_FINALIZE_VARNAMES="SWAYSOCK I3SOCK SCROLLSOCK XCURSOR_SIZE XCURSOR_THEME"
}
