{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.theming;
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
      # tinty is the scheme-switcher for the tinty-based theming flow; in the
      # noctalia session Noctalia's builtin templates own app theming instead.
      ++ lib.optional (config.modules.desktop.session != "noctalia") pkgs.tinty;
  };
}
