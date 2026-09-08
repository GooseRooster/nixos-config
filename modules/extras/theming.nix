{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.gnomad.nixosModules.gnomad
  ];

  options.modules.theming.enable =
    lib.mkEnableOption "theming tools (gnomad, tinty, gowall)";

  config = lib.mkIf config.modules.theming.enable {
    # `gnomad` is built by its own flake (see ../flake.nix); the module installs
    # the wrapped binary (git/gowall/tinty/gsettings baked into its PATH).
    # It owns the GNOME colour-scheme (and thus light/dark mode) toggling.
    programs.gnomad.enable = true;

    environment.systemPackages = with pkgs; [
      gowall
      # tinty is the scheme-switcher for the tinty-based theming flow
      # (terminal, claude-code, …; see the dotfiles' misc-config.nix).
      tinty
    ];
  };
}
