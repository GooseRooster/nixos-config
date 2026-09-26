# Now Playing Card settings — shared across hosts.
#
#  the extension's own runtime state is not
# managed. All values are soft defaults (see gnome-dconf.nix). The enum-valued
# keys (location, card-layout, cover-size, equalizer-style, panel-text) are
# stored as their schema nick strings.
{ ... }:

{
  modules.gnome.dconf.settings = {
    "org/gnome/shell/extensions/nowplaying" = {
      animate-icon = true;
      card-layout = "auto";
      cover-size = "large";
      equalizer-style = "rounded";
      location = "panel";
      panel-controls = false;
      panel-text = "none";
      show-loop-shuffle = true;
      show-volume = true;
    };
  };
}
