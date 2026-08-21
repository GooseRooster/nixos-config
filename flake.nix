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

    # GNOME Shell extensions built from source (not in nixpkgs/EGO). Pinned as
    # flake inputs (flake = false) so `nix flake update` / CI keeps them current
    # with no manual rev/hash management.
    gradia-capture = {
      url = "github:AlexanderVanhee/gradia-capture";
      flake = false;
    };
    bazaar-companion = {
      url = "github:bazaar-org/bazaar-companion";
      flake = false;
    };
    paperwm = {
      url = "github:paperwm/PaperWM/develop";
      flake = false;
    };

    # CLI batteries live in their own repo. Safe to follow our nixpkgs.
    cli.url = "github:GooseRooster/nix-cli";
    cli.inputs.nixpkgs.follows = "nixpkgs";

    # GNOME colour-scheme TUI (theming). Safe to follow our nixpkgs.
    gnomad.url = "github:GooseRooster/gnomad";
    gnomad.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager (the tool) + our dotfiles repo (the config).
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:GooseRooster/home-manager";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nix-cli.follows = "cli";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning/formatting (btrfs layout for the host).
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
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

      # Exposed so `disko` can partition/format without a full system build:
      #   nix run github:nix-community/disko/latest -- --mode disko --flake github:GooseRooster/nixos-config#home
      diskoConfigurations.home = {
        imports = [ ./hosts/home/disko.nix ];
      };
    };
}
