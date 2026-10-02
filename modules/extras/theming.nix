{ config, lib, pkgs, ... }:

let
  cfg = config.modules.theming;

  # The Noctalia CLI for the wallpaper-conversion helper's IPC path (palette
  # reads, config reload, notifications); prefer the package the running
  # session shell was built from (programs.noctalia, set by the noctalia
  # flake module), falling back to nixpkgs.
  noctaliaPkg =
    if config.programs.noctalia.package != null
    then config.programs.noctalia.package
    else pkgs.noctalia;

  # Recolors ~/Pictures/Wallpapers with the active Noctalia palette (gowall)
  # and repoints the wallpaper slideshow at the converted set. Everything it
  # does beyond the conversion runs through the Noctalia IPC.
  gowallConvertWallpapers = pkgs.writeShellApplication {
    name = "gowall_convert_wallpapers";
    runtimeInputs = with pkgs; [
      gowall
      jq
      noctaliaPkg
    ];
    text = builtins.readFile ./gowall_convert_wallpapers;
  };

  # Batch refresh hook for "palette changed": reruns everything that caches
  # the palette. Edit ./theme_regen to add/remove steps.
  themeRegen = pkgs.writeShellApplication {
    name = "theme_regen";
    runtimeInputs = [
      pkgs.sway
      gowallConvertWallpapers
    ];
    text = builtins.readFile ./theme_regen;
  };
in
{
  options.modules.theming.enable =
    lib.mkEnableOption "theming tools (gowall wallpaper recoloring)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.gowall
      gowallConvertWallpapers
      themeRegen
    ];
  };
}
