{ config, lib, pkgs, ... }:

{
  # Declaratively installed GNOME Shell extensions. They are installed (so they
  # appear in Extension Manager), but *enabled* manually via the Extension
  # Manager flatpak (com.mattjakeman.ExtensionManager).
  #
  # NOTE: bazaar-integration and gradia-integration are intentionally absent.
  # They are NOT bundled in the Bazaar/Gradia flatpaks and are NOT packaged in
  # nixpkgs `gnomeExtensions` — they are standalone shell extensions on
  # extensions.gnome.org (e.g. "Gradia Capture"). Install them manually via
  # Extension Manager, or package them here with buildGnomeExtension later.
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
