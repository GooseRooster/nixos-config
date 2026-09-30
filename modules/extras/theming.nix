{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.theming;
  isNoctalia = config.modules.desktop.session == "noctalia";

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
  # does beyond the conversion runs through the Noctalia IPC, so it only
  # ships in the noctalia session.
  gowallConvertWallpapers = pkgs.writeShellApplication {
    name = "gowall_convert_wallpapers";
    runtimeInputs = with pkgs; [
      gowall
      jq
      noctaliaPkg
    ];
    text = builtins.readFile ./gowall_convert_wallpapers;
  };
in
{
  imports = [
    inputs.gnomad.nixosModules.gnomad
  ];

  options.modules.theming.enable =
    lib.mkEnableOption "theming tools (gnomad, tinty, gowall)";

  config = lib.mkIf cfg.enable {
    # `gnomad` is built by its own flake (see ../flake.nix); the module installs
    # the wrapped binary (git/gowall/tinty/gsettings baked into its PATH).
    # GNOME-only: its colour-scheme toggles are meaningless outside GNOME
    # (Noctalia owns the color scheme in the noctalia session).
    programs.gnomad.enable = config.modules.desktop.session == "gnome";

    environment.systemPackages =
      [ pkgs.gowall ]
      # noctalia-session-only wallpaper conversion helper (see above)
      ++ lib.optional isNoctalia gowallConvertWallpapers
      # tinty is the scheme-switcher for the tinty-based theming flow; in the
      # noctalia session Noctalia's builtin templates own app theming instead.
      ++ lib.optional (config.modules.desktop.session != "noctalia") pkgs.tinty;
  };
}
