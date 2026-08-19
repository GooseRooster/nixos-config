{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.scroll.nixosModules.default ];

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

    # Keybinds, layout, and `exec noctalia` live in chezmoi
    # (~/.config/scroll/config). Noctalia's lockscreen + idle replace
    # swaylock/swayidle, so those are intentionally omitted here.
    extraPackages = with pkgs; [
      foot
      wmenu
      brightnessctl
      grim
      slurp
      wl-clipboard
    ];
  };
}
