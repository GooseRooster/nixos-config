# Weather or Not settings — shared across hosts.
#
# Soft default (see gnome-dconf.nix).
{ ... }:

{
  modules.gnome.dconf.settings = {
    "org/gnome/shell/extensions/weatherornot" = {
      position = "clock-left-centered";
    };
  };
}
