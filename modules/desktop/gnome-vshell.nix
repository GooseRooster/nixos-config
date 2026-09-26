# V-Shell (vertical-workspaces@G-dH.github.com) settings — shared across hosts.
# All values are soft defaults (see gnome-dconf.nix).
{
  lib,
  ...
}:

let
  gv = lib.gvariant;
in

{
  modules.gnome.dconf.settings = {
    "org/gnome/shell/extensions/vertical-workspaces" = {
      # Workspace thumbnails / dash placement.
      ws-thumbnails-position = gv.mkInt32 0;
      dash-position = gv.mkInt32 3;
      dash-bg-color = gv.mkInt32 0;

      # Overview / app-grid background treatment.
      animation-speed-factor = gv.mkInt32 50;
      app-grid-bg-blur-sigma = gv.mkInt32 30;
      app-grid-bg-brightness = gv.mkInt32 70;
      overview-bg-blur-sigma = gv.mkInt32 25;
      overview-bg-brightness = gv.mkInt32 70;

      # Behaviour.
      startup-state = gv.mkInt32 1;
      window-attention-mode = gv.mkInt32 2;
      hot-corner-action = gv.mkInt32 0;
      app-grid-performance = true;
      enable-page-shortcuts = false;
    };
  };
}
