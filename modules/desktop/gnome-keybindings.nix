# Shared keyboard shortcuts (same on every GNOME install):
#   - window-manager / mutter / shell built-in bindings
#   - custom command bindings (gsd media-keys)
#
# Ported from the live user-db. Explicit empty-array keys are intentional
# clears (binding disabled so PaperWM can own the behaviour), ported so fresh
# installs behave the same as this machine. PaperWM's own bindings live in
# gnome-paperwm.nix. All values are soft defaults (see gnome-dconf.nix).
{
  lib,
  ...
}:

let
  gv = lib.gvariant;
  # Empty string array — dconf's "no binding" / unset marker (@as []).
  empty = gv.mkEmptyArray gv.type.string;
in

{
  modules.gnome.dconf.settings = {
    # Window manager: strip the defaults that conflict with PaperWM's scheme;
    # keep vertical workspace-move bindings on <Super><Shift>Page_{Up,Down}.
    "org/gnome/desktop/wm/keybindings" = {
      maximize = empty;
      minimize = empty;
      move-to-monitor-down = empty;
      move-to-monitor-left = empty;
      move-to-monitor-right = empty;
      move-to-monitor-up = empty;
      move-to-workspace-down = [ "<Super><Shift>Page_Down" ];
      move-to-workspace-up = [ "<Super><Shift>Page_Up" ];
      switch-applications = empty;
      switch-applications-backward = empty;
      switch-group = empty;
      switch-group-backward = empty;
      switch-input-source = empty;
      switch-input-source-backward = empty;
      switch-panels = empty;
      switch-panels-backward = empty;
      switch-to-workspace-1 = empty;
      switch-to-workspace-down = empty;
      switch-to-workspace-last = empty;
      switch-to-workspace-left = empty;
      switch-to-workspace-right = empty;
      switch-to-workspace-up = empty;
      unmaximize = empty;
    };

    # Mutter: edge tiling & snap bindings off (PaperWM handles tiling).
    "org/gnome/mutter/keybindings" = {
      cancel-input-capture = [ "<Super><Shift>Escape" ];
      toggle-tiled-left = empty;
      toggle-tiled-right = empty;
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [ "<Super>Escape" ];
    };

    "org/gnome/shell/keybindings" = {
      focus-active-notification = [ "<Super>n" ];
      shift-overview-down = empty;
      shift-overview-up = empty;
      toggle-message-tray = [ "<Super>n" ];
    };

    # gsd media keys + custom command bindings (relocatable-schema paths).
    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = [ "<Shift><Super>i" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
      logout = [ "<Control><Super>Delete" ];
      magnifier = empty;
      magnifier-zoom-in = empty;
      magnifier-zoom-out = empty;
      rotate-video-lock-static = empty;
      screenreader = empty;
      screensaver = [ "<Control><Alt>l" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>e";
      command = "termapp yazi";
      name = "yazi";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>Return";
      command = "ghostty";
      name = "term";
    };
  };
}
