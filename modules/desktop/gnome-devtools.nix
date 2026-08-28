{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.modules.desktop.session == "gnome") {
    # GNOME core developer tools that have no Flatpak equivalent.
    # (gnome-builder is installed as a Flatpak instead.)
    services.sysprof.enable = true; # system-wide profiler daemon

    environment.systemPackages = with pkgs; [
      devhelp   # API documentation browser
      d-spy     # D-Bus inspector
      sysprof   # system/kernel profiler

      # dconf-editor + Extension Manager are native too: their flatpaks can't
      # browse host GSettings schemas (org.gnome.shell, extension schemas) that
      # live in the Nix store outside the sandbox.
      dconf-editor
      gnome-extension-manager
    ];
  };
}
