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
      wineWow64Packages.wayland
      winetricks
      faugus-launcher
    ];
  };
}
