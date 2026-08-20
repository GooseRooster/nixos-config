{ config, lib, pkgs, ... }:

{
  # Declaratively installed GNOME Shell extensions. They are installed (so they
  # appear in Extension Manager), but *enabled* manually via the Extension
  # Manager flatpak (com.mattjakeman.ExtensionManager).
  #
  # NOTE: bazaar-integration and gradia-integration are intentionally absent —
  # they ship inside the io.github.kolunmi.Bazaar / be.alexandervanhee.gradia
  # Flatpaks (already in modules/flatpak/base.nix).
  environment.systemPackages = with pkgs.gnomeExtensions; [
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
  ];
}
