{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty        # terminal emulator
    wl-clipboard   # wl-copy / wl-paste
    brightnessctl  # backlight control
  ];

  # Make Ghostty the default terminal. GNOME 50's GLib no longer reads
  # org.gnome.desktop.default-applications.terminal for `Terminal=true` .desktop
  # entries (e.g. neovim) — it tries `xdg-terminal-exec` first from a hardcoded
  # list, so point that at Ghostty's desktop entry.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };
}
