{ config, lib, pkgs, inputs, ... }:

let
  # Not in nixpkgs `gnomeExtensions` (and not on extensions.gnome.org), so
  # built from source. The sources come from the flake inputs (flake = false),
  # so they're version-pinned by flake.lock and updated by `nix flake update`.
  gradia-capture = pkgs.callPackage ../../pkgs/gnome-extensions/gradia-capture { src = inputs.gradia-capture; };
  bazaar-companion = pkgs.callPackage ../../pkgs/gnome-extensions/bazaar-companion { src = inputs.bazaar-companion; };
in
{
  # Declaratively installed GNOME Shell extensions. They are installed (so they
  # appear in Extension Manager), but *enabled* manually via the Extension
  # Manager flatpak (com.mattjakeman.ExtensionManager).
  environment.systemPackages = (with pkgs.gnomeExtensions; [
    user-themes            # user-theme@gnome-shell-extensions.gcampax.github.com
    vitals                 # Vitals@CoreCoding.com
    clipboard-indicator    # clipboard-indicator@tudmotu.com
    weatherpanel           # weatherpanel@attentivecoder
    medialine              # medialine@funinkina.co.in
    lock-guard             # lock-guard@fthx
    wallpaper-slideshow    # azwallpaper@azwallpaper.gitlab.com
    mouse-follows-focus-2  # mouse-follows-focus@crisidev.org
    paperwm                # paperwm@paperwm.github.com
    hot-edge               # hotedge@jonathan.jdoda.ca
    grand-theft-focus      # grand-theft-focus@zalckos.github.com
    blur-my-shell          # blur-my-shell@aunetx
    caffeine               # caffeine@patapon.info
    gsconnect              # gsconnect@andyholmes.github.io
    logo-menu              # logomenu@aryan_k
  ]) ++ [
    gradia-capture         # gradia-integration@alexandervanhee.github.io
    bazaar-companion       # bazaar-integration@kolunmi.github.io
  ];
}
