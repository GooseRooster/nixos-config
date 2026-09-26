# Clipboard Indicator settings — shared across hosts.
#
# Ported from the live user-db; clipboard history itself is user data and is
# not managed. All values are soft defaults (see gnome-dconf.nix).
{ ... }:

{
  modules.gnome.dconf.settings = {
    "org/gnome/shell/extensions/clipboard-indicator" = {
      open-at-cursor = true;
      toggle-menu = [ "<Super>Insert" ];
    };
  };
}
