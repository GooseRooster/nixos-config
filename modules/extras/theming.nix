{ config, lib, pkgs, ... }:

let
  cfg = config.modules.theming;
in
{
  options.modules.theming.enable =
    lib.mkEnableOption "theming tools (tinty, gowall)";

  config = lib.mkIf cfg.enable {
    # `gnomad` is a custom Homebrew tap and has no nixpkgs equivalent — it is
    # intentionally omitted here and remains with chezmoi for now.
    environment.systemPackages = with pkgs; [
      tinty
      gowall
    ];
  };
}
