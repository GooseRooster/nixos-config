{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.wine.enable = lib.mkEnableOption ''
    native Wine + winetricks + Faugus Launcher instead of their Flatpaks.
    Pair with modules.graphics.gaming for the 32-bit GL/VA-API runtime.
  '';

  config = lib.mkIf config.modules.wine.enable {
    environment.systemPackages = with pkgs; [
      # wineWowPackages: combined 64-bit + 32-bit builds (vs winePackages).
      # The .wayland flavour is the nixpkgs-recommended gaming build on
      # Wayland compositors (Wayland driver + XWayland support).
      # For the single-process WoW64 mode (what the org.winehq.Wine flatpak's
      # wow64 branch shipped), use wineWow64Packages.wayland instead.
      wineWowPackages.wayland
      winetricks
      faugus-launcher
    ];
  };
}
