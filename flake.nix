{
  description = "NixOS — Flatpak-first GNOME desktop + CLI batteries (CachyOS kernel)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Precompiled CachyOS kernels. `release` branch has a binary cache.
    # Do NOT override its nixpkgs input (the pinned overlay needs the exact
    # revision to hit the cache).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Declarative flatpak installs (nixpkgs removed services.flatpak.packages).
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # CLI batteries live in their own repo. Safe to follow our nixpkgs.
    cli.url = "github:GooseRooster/nixos-cli";
    cli.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
    in
    {
      nixosConfigurations.vm = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/vm
        ];
      };

      nixosConfigurations.home = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/home
        ];
      };
    };
}
