{
  config,
  lib,
  pkgs,
  ...
}:

let
  isNoctalia = config.modules.desktop.session == "noctalia";
in
{
  # Sway (Wayland compositor) for the noctalia session stack. Replaces the
  # scrolling Umbriel compositor with a standard dynamic-tiling one; the
  # Noctalia shell + session plumbing live in noctalia.nix. The actual
  # config (keybinds, autostart, output/input) is written by the dotfiles'
  # Home-Manager sway module (~/.config/sway/config).
  config = lib.mkIf isNoctalia {
    programs.sway = {
      enable = true;
      xwayland.enable = true;

      # Wayland-first app backends + the Vulkan renderer (the intended wlroots
      # path forward; required for HDR10 output). Exported before Sway starts.
      extraSessionCommands = ''
        export GDK_BACKEND="wayland,x11"
        export SDL_VIDEODRIVER=wayland
        export CLUTTER_BACKEND=wayland
        export QT_QPA_PLATFORM="wayland;xcb"
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export MOZ_ENABLE_WAYLAND=1
        export WLR_RENDERER=vulkan
      '';

      # Sway's own sed-like tooling; Noctalia provides the shell/lockscreen/
      # idle, so the module's default swaylock/swayidle/foot/wmenu are omitted.
      extraPackages = with pkgs; [
        autotiling
        brightnessctl
        grim
        playerctl
        slurp
        udiskie # USB/removable-media automount daemon (autostarted from Sway)
        wl-clipboard
      ];
    };

    # Removable-media handling. GNOME gets this implicitly (udisks2 + gvfs +
    # gsd); a bare Sway session doesn't, so enable the udisks2 D-Bus service
    # (polkit is already on via noctalia.nix) and let udiskie mount/unmount
    # hotplugged drives (autostarted in the dotfiles sway config).
    services.udisks2.enable = true;

    # Portals. nixpkgs' Sway module already maps Screenshot/ScreenCast to the
    # wlr backend and everything else to gtk; the gnome portal fills the gaps
    # gtk leaves (Background for flatpak autostart/background, GlobalShortcuts)
    # and gnome-keyring supplies Secret so credential-storing flatpaks work.
    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-wlr
    ];

    xdg.portal.config.sway = {
      "org.freedesktop.impl.portal.Background" = [ "gnome" ];
      "org.freedesktop.impl.portal.GlobalShortcuts" = [ "gnome" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
