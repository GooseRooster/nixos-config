{
  description = "NixOS — Flatpak-first noctalia desktop + CLI batteries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Declarative flatpak installs (nixpkgs removed services.flatpak.packages).
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # GNOME Shell extensions built from source (not in nixpkgs/EGO). Pinned as
    # flake inputs (flake = false) so `nix flake update` keeps them current
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
    nowplaying-card = {
      url = "github:epogonii/nowplaying-card";
      flake = false;
    };

    # Hatter icon theme (not in nixpkgs). Pinned the same way as the
    # extensions above; packaged in pkgs/hatter.
    hatter = {
      url = "github:Mibea/Hatter";
      flake = false;
    };

    # GNOME colour-scheme TUI (theming). Safe to follow our nixpkgs.
    gnomad.url = "github:GooseRooster/gnomad";
    gnomad.inputs.nixpkgs.follows = "nixpkgs";

    # Noctalia v5 (C++ desktop shell) for the lightweight DE stack
    # (modules/desktop/noctalia.nix). Pairs with Sway (modules/desktop/sway.nix)
    # as the compositor. Requires nixpkgs unstable.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager (the tool) + our dotfiles repo (the config + CLI bundles).
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:GooseRooster/home-manager";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";

    # Steam skin that makes the client look native (replaces Millennium, see
    # modules/gaming/steam.nix). Pinned as flake = false like the extensions:
    # install.py runs from this source tree at activation/refresh time.
    adwaita-for-steam = {
      url = "github:tkashkin/Adwaita-for-Steam";
      flake = false;
    };

    # Zen Browser (native, not the Flatpak). Community flake, twilight
    # variant for reproducible artifact pinning.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Secure Boot (UKI signing via sbctl). Safe to follow our nixpkgs.
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Binary cache for Noctalia (skip building the v5 C++ shell locally).
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      # oo7 0.6.0 (nixpkgs) has a ~50% startup deadlock in its daemon;
      # override the oo7 package set with 0.7.0.beta. See pkgs/oo7-beta.nix.
      oo7Overlay = import ./pkgs/oo7-beta.nix;
    in
    {

      nixosConfigurations.home = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/home
          { nixpkgs.overlays = [ oo7Overlay ]; }
        ];
      };

      nixosConfigurations.laptop = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop
          { nixpkgs.overlays = [ oo7Overlay ]; }
        ];
      };
    };
}
