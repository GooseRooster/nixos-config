{ config, lib, pkgs, inputs, ... }:

let
  # Not in nixpkgs `gnomeExtensions` (and not on extensions.gnome.org), so
  # built from source. The sources come from the flake inputs (flake = false),
  # so they're version-pinned by flake.lock and updated by `nix flake update`.
  custom = {
    gradia-capture = pkgs.callPackage ../../pkgs/gnome-extensions/gradia-capture { src = inputs.gradia-capture; };
    bazaar-companion = pkgs.callPackage ../../pkgs/gnome-extensions/bazaar-companion { src = inputs.bazaar-companion; };
    paperwm = pkgs.callPackage ../../pkgs/gnome-extensions/paperwm { src = inputs.paperwm; };
  };

  upstream = with pkgs.gnomeExtensions; [
    user-themes            # user-theme@gnome-shell-extensions.gcampax.github.com
    vitals                 # Vitals@CoreCoding.com
    clipboard-indicator    # clipboard-indicator@tudmotu.com
    weatherpanel           # weatherpanel@attentivecoder
    medialine              # medialine@funinkina.co.in
    lock-guard             # lock-guard@fthx
    wallpaper-slideshow    # azwallpaper@azwallpaper.gitlab.com
    mouse-follows-focus-2  # mouse-follows-focus@crisidev.org
    hot-edge               # hotedge@jonathan.jdoda.ca
    grand-theft-focus      # grand-theft-focus@zalckos.github.com
    blur-my-shell          # blur-my-shell@aunetx
    caffeine               # caffeine@patapon.info
    gsconnect              # gsconnect@andyholmes.github.io
  ];

  allExtensions = upstream ++ builtins.attrValues custom;
in
{
  # Declaratively installed GNOME Shell extensions.
  environment.systemPackages = allExtensions;

  # Also enabled by default. These are dconf *defaults* (the system-db sits
  # below the user-db), so the user can still toggle any extension in
  # Extension Manager. Note `enabled-extensions` is a list-typed key, so any
  # manual toggle writes the whole list to the user db and overrides these.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/shell" = {
          enabled-extensions = map (e: e.extensionUuid) allExtensions;
        };
      };
    }
  ];
}
