{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Sway (Wayland compositor) for the noctalia session stack. Replaces the
  # scrolling Umbriel compositor with a standard dynamic-tiling one; the
  # Noctalia shell + session plumbing live in noctalia.nix. The actual
  # config (keybinds, autostart, output/input) is written by the dotfiles'
  # Home-Manager sway module (~/.config/sway/config).
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

      # gcr-ssh-agent (the SSH agent; gnome-keyring dropped its SSH component)
      # exposes its socket here but only sets the systemd user environment,
      # which a bare Sway session never imports. Export it so shells/GUI apps
      # inherit it (GNOME's session manager did this automatically).
      export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/gcr/ssh"
    '';

    # Sway's own sed-like tooling; Noctalia provides the shell/lockscreen/
    # idle, so the module's default swaylock/swayidle/foot/wmenu are omitted.
    extraPackages = with pkgs; [
      autotiling
      brightnessctl
      fuzzel # screen-share source chooser for xdg-desktop-portal-wlr
      grim
      playerctl
      slurp
      udiskie # USB/removable-media automount daemon (autostarted from Sway)
      wl-clipboard
    ];
  };

  # Removable-media handling. A bare Sway session doesn't get udisks2 + gvfs
  # implicitly, so enable the udisks2 D-Bus service (polkit is already on via
  # noctalia.nix) and let udiskie mount/unmount hotplugged drives
  # (autostarted in the dotfiles sway config).
  services.udisks2.enable = true;

  # Portals. nixpkgs' Sway module already maps Screenshot/ScreenCast to the
  # wlr backend and everything else to gtk; the gnome portal fills the gaps
  # gtk leaves (Background for flatpak autostart/background, GlobalShortcuts)
  # and gnome-keyring supplies Secret (its .portal is UseIn=gnome, so an
  # explicit mapping is needed here) so credential-storing flatpaks work.
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

  # Screen-sharing source chooser for xdg-desktop-portal-wlr. The NixOS module
  # generates the config and forces --config=<it>, so a user-level
  # ~/.config/xdg-desktop-portal-wlr/config is ignored. Browsers request
  # monitor+window (kAnyScreenContent), which makes xdpw skip its slurp-only
  # fallback and require a dmenu-style chooser; without one the share fails
  # ("no output found"). Use an absolute fuzzel path because the service's
  # systemd PATH does not include the user profile.
  xdg.portal.wlr.settings.screencast = {
    chooser_type = "dmenu";
    chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -l 10 -p 'Select a source to share:'";
  };

  # Sway has no session manager, so nothing starts the XDG autostart units
  # systemd-xdg-autostart-generator creates from ~/.config/autostart (e.g.
  # the flatpak Background portal writes mini-eq's entry there at runtime).
  # Pull in systemd's target for exactly this case: DEs that don't manage
  # autostart themselves. Without it the units are generated but never run.
  systemd.user.targets.graphical-session.wants = [
    "xdg-autostart-if-no-desktop-manager.target"
  ];
}
