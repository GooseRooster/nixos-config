# PaperWM tiling settings, window rules and its own keybindings — shared
# across hosts (per-workspace entries stay imperative on each machine).
#
# Ported from the live user-db; PaperWM runtime state (`last-used-display-server`,
# `restore-*` migration memory) is intentionally not managed. The mutter keys
# here are what PaperWM's setup turns off so its own tiling takes over.
# All values are soft defaults (see gnome-dconf.nix).
{
  lib,
  pkgs,
  ...
}:

let
  gv = lib.gvariant;
in

{
  modules.gnome.dconf.settings = {
    # Mutter, adjusted for PaperWM: native edge tiling / snapping / modal
    # attach off, workspaces shared across monitors.
    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      center-new-windows = true;
      edge-tiling = false;
      experimental-features = gv.mkEmptyArray gv.type.string;
      workspaces-only-on-primary = false;
    };

    "org/gnome/shell/extensions/paperwm" = {
      disable-topbar-styling = false;
      show-window-position-bar = true;

      # The workspace pill indicator in the top bar.
      show-workspace-indicator = false;

      # Window rules — each entry is a JSON winprop string
      # (https://github.com/paperwm/PaperWM#window-rules).
      winprops = [
        ''{"wm_class":"/.*ghostty.*/i","preferredWidth":"35%"}''
      ];

    };

    # PaperWM's own bindings (vim-style switch/move over a window stack).
    "org/gnome/shell/extensions/paperwm/keybindings" = {
      close-window = [ "<Super>q" ];

      move-down = [
        "<Control><Super>Down" "<Shift><Super>j"
      ];
      move-down-workspace = [
        "<Control><Super>Page_Down" "<Shift><Control><Super>j"
      ];
      move-left = [
        "<Control><Super>comma" "<Shift><Super>comma"
        "<Control><Super>Left" "<Shift><Super>h"
      ];
      move-right = [
        "<Control><Super>period" "<Shift><Super>period"
        "<Control><Super>Right" "<Shift><Super>l"
      ];
      move-up = [
        "<Control><Super>Up" "<Shift><Super>k"
      ];
      move-up-workspace = [
        "<Control><Super>Page_Up" "<Shift><Control><Super>k"
      ];

      new-window = [ "" ];

      switch-down = [ "<Super>Down" "<Super>j" ];
      switch-down-workspace = [ "<Super>Page_Down" ];
      switch-down-workspace-from-all-monitors = [ "<Alt><Super>j" ];
      switch-left = [ "<Super>Left" "<Super>h" ];
      switch-right = [ "<Super>Right" "<Super>l" ];
      switch-up = [ "<Super>Up" "<Super>k" ];
      switch-up-workspace = [ "<Super>Page_Up" ];
      switch-up-workspace-from-all-monitors = [ "<Alt><Super>k" ];

      toggle-scratch = [ "" ];
      toggle-scratch-layer = [ "" ];
      toggle-scratch-window = [ "" ];
    };
  };

  # PaperWM seeds ~/.config/paperwm/{user.css,metadata.json} itself by copying
  # them out of its read-only nix store extension dir (updateUserConfigFiles in
  # extension.js); Gio.FileCopyFlags preserves the store's 0444 mode, so those
  # files land read-only and stay that way — and its metadata re-copy then
  # fails on every enable. This oneshot makes them user-writable again at
  # session start so user.css can be edited on the fly (rebuild-free theming;
  # reload = disable + re-enable PaperWM). Idempotent chmod, safe to rerun.
  systemd.user.services.paperwm-writable-config = {
    description = "Make PaperWM user config files writable";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chmod --quiet u+w %h/.config/paperwm/user.css %h/.config/paperwm/metadata.json 2>/dev/null || true'";
    };
    unitConfig.ConditionPathExists = "%h/.config/paperwm";
  };
}
