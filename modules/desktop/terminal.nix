{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty        # terminal emulator
    wl-clipboard   # wl-copy / wl-paste
    brightnessctl  # backlight control
  ];

  # Make Ghostty the default terminal. GNOME's default is org.gnome.Terminal,
  # which we don't install, so `Terminal=true` .desktop entries (e.g. neovim)
  # silently fail without this.
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.default-applications.terminal]
    exec='ghostty'
    exec-arg='-e'
  '';
}
