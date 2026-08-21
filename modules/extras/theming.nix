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
    programs.gnomad.enable = true;

    environment.systemPackages = with pkgs; [
      tinty
      gowall
    ];
  };
}
