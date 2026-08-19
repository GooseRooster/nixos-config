{
  description = "NixOS — lightweight Bluefin-like desktop (Scroll + Noctalia + UWSM)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    scroll.url = "github:Diax170/scroll-flake";
    scroll.inputs.nixpkgs.follows = "nixpkgs";

    # Pin to the `cachix` branch so pre-built binaries are used.
    # Do NOT set `inputs.nixpkgs.follows`, or the cache will miss.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    noctalia-greeter.inputs.nixpkgs.follows = "nixpkgs";

    # CLI batteries live in their own repo. Local path for now; once pushed:
    #   cli.url = "github:<you>/nixos-cli";
    cli.url = "path:../nixos-cli";
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
    };
}
