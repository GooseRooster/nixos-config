{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.steam.enable = lib.mkEnableOption ''
    native Steam (Millennium-flavoured) instead of the Flatpak Steam.
    32-bit GL / VA-API extras come from modules.graphics.gaming.
  '';

  config = lib.mkIf config.modules.steam.enable {
    # Millennium's official flake exposes an overlay with `millennium-steam`:
    # a Steam package with the Millennium theme/plugin framework pre-patched
    # in. Millennium does not support the Flatpak Steam, so this replaces it.
    nixpkgs.overlays = [ inputs.millennium.overlays.default ];

    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;
    };
  };
}
