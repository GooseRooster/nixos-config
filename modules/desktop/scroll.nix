{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.scroll.nixosModules.default ];

  # The scroll module injects a sway-style systemd integration into
  # /etc/scroll/config.d/nixos.conf (dbus-update-activation-environment +
  # `systemctl --user start scroll-session.target`). That conflicts with UWSM:
  # UWSM's wayland-wm@scroll.service is Type=notify and waits for the compositor
  # to signal readiness via `uwsm finalize`. Without it, UWSM times out (~30s),
  # tears the session down and returns to the greeter. Replace it with the
  # UWSM-compatible readiness line.
  environment.etc."scroll/config.d/nixos.conf".source = lib.mkForce (
    pkgs.writeText "scroll-uwsm.conf" ''
      exec exec uwsm finalize SWAYSOCK I3SOCK SCROLLSOCK XCURSOR_SIZE XCURSOR_THEME
    ''
  );

  # Minimal *system default* scroll config so the VM is usable before chezmoi
  # applies ~/.config/scroll/config (which always takes precedence). No `bar`
  # block: Noctalia provides the bar/launcher/notifications, so the default
  # scroll status bar is intentionally omitted here.
  environment.etc."scroll/config".text = ''
    set $mod Mod4
    set $term ghostty

    # UWSM readiness + session env import (see overridden nixos.conf above).
    include /etc/scroll/config.d/*

    # Essentials. No launcher binding: Noctalia's launcher is triggered via IPC
    # from the chezmoi scroll config.
    bindsym $mod+Return exec $term
    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+e exit
    bindsym $mod+q kill
    bindsym $mod+f fullscreen toggle
    bindsym $mod+space focus mode_toggle

    # Focus
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # Workspaces
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10
  '';

  programs.scroll = {
    enable = true;
    xwayland.enable = true;

    extraSessionCommands = ''
      # Wayland-first app backends
      export GDK_BACKEND="wayland,x11"
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
      export QT_QPA_PLATFORM="wayland;xcb"
      export ELECTRON_OZONE_PLATFORM_HINT=wayland

      # Desktop identity (matches xdg.portal.config.scroll from the module)
      export XDG_CURRENT_DESKTOP=scroll
      export XDG_SESSION_TYPE=wayland
      export XDG_SESSION_DESKTOP=scroll

      # Cursor
      export XCURSOR_THEME=Adwaita
      export XCURSOR_SIZE=24
    '';

    # Full keybinds/layout live in chezmoi (~/.config/scroll/config), which
    # overrides the minimal system default above. Noctalia is started as a
    # systemd user service (see noctalia.nix), NOT exec'd from scroll config —
    # and its lockscreen + idle replace swaylock/swayidle, so those are omitted.
    extraPackages = with pkgs; [
      ghostty
      brightnessctl
      grim
      slurp
      wl-clipboard
    ];
  };
}
