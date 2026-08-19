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

  # UWSM has no `scroll` plugin (its `sway` plugin keys off ~/.config/sway and
  # SWAYSOCK, neither of which applies to scroll). So scroll signals readiness
  # itself via `uwsm finalize` in its config (see scroll.nix), which exports
  # WAYLAND_DISPLAY plus SWAYSOCK/I3SOCK/SCROLLSOCK/XCURSOR_* into the session
  # environment. wayland-wm@scroll.service is Type=notify and depends on that
  # readiness signal.
}
