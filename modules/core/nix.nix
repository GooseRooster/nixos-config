{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # nixpkgs already defaults to ["root"] here; adding @wheel lets flake
    # `nixConfig` substituters be honoured (e.g. a project's cachix in
    # flake.nix) instead of being ignored with an "untrusted user" warning.
    trusted-users = [ "@wheel" ];
  };
}
