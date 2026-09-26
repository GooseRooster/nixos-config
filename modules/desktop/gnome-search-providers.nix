# G-dH search-provider settings (Extensions + Windows) — shared across hosts.
#
# Both extensions expose a `dash-icon-position` int (index into the overview
# search results ordering). soft defaults (see
# gnome-dconf.nix).
{
  lib,
  ...
}:

let
  gv = lib.gvariant;
in

{
  modules.gnome.dconf.settings = {
    "org/gnome/shell/extensions/extensions-search-provider" = {
      dash-icon-position = gv.mkInt32 0;
    };

    "org/gnome/shell/extensions/windows-search-provider" = {
      dash-icon-position = gv.mkInt32 0;
    };
  };
}
