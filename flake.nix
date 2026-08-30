{
  description = "NixOS — Flatpak-first GNOME desktop + CLI batteries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    # CLI batteries now live in the home-manager repo (home.bundles.* in
    # home.packages) — no separate flake input.

    # GNOME colour-scheme TUI (theming). Safe to follow our nixpkgs.
    gnomad.url = "github:GooseRooster/gnomad";
    gnomad.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager (the tool) + our dotfiles repo (the config + CLI bundles).
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:GooseRooster/home-manager";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";

    # Steam Millennium (theme/plugin framework for the Steam client). Its
    # sub-flake pins its own nixpkgs and exposes an overlay providing
    # `millennium-steam` for programs.steam.package (see modules/gaming/steam.nix).
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    # Noctalia v5 (C++ desktop shell) + Umbriel (its Wayland compositor) for
    # the lightweight DE stack (modules/desktop/noctalia.nix). Both require
    # nixpkgs unstable.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel = {
      # Must use the Git fetcher: the flake declares `self.submodules = true`
      # (it vendors scenefx as a git submodule), which the `github:` tarball
      # scheme does not support.
      url = "git+https://github.com/noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser (native, not the Flatpak: Noctalia's zen-browser template
    # only discovers native ~/.zen profiles). Community flake, twilight
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
