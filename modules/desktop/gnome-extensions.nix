{ config, lib, pkgs, inputs, ... }:

let
  gv = lib.gvariant;

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
    dynamic-music-pill     # dynamic-music-pill@andbal
    lock-guard             # lock-guard@fthx
    wallpaper-slideshow    # azwallpaper@azwallpaper.gitlab.com
    mouse-follows-focus-2  # mouse-follows-focus@crisidev.org
    grand-theft-focus      # grand-theft-focus@zalckos.github.com
    esp-extensions-search-provider # extensions-search-provider@G-dH.github.com
    vertical-workspaces    # vertical-workspaces@G-dH.github.com (V-Shell)
    wsp-windows-search-provider # windows-search-provider@G-dH.github.com
    wtmb-window-thumbnails # window-thumbnails@G-dH.github.com
    blur-my-shell          # blur-my-shell@aunetx
    caffeine               # caffeine@patapon.info
    gsconnect              # gsconnect@andyholmes.github.io
  ];

  # Caffeine ships its cup icons only inside the extension directory, which
  # St.IconTheme doesn't search; the extension's file-path fallback fails to
  # render under gnome-shell (blank indicator, see journal "Could not load a
  # pixbuf from icon theme"). Symlinking them into the system hicolor theme
  # fixes it, since every theme (incl. Hatter) inherits from hicolor and the
  # extension then takes its normal ThemedIcon path.
  hicolor-with-caffeine-icons = pkgs.hicolor-icon-theme.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p "$out/share/icons/hicolor/scalable/actions"
      for f in ${pkgs.gnomeExtensions.caffeine}/share/gnome-shell/extensions/caffeine@patapon.info/icons/hicolor/scalable/actions/*.svg; do
        ln -s "$f" "$out/share/icons/hicolor/scalable/actions/$(basename "$f")"
      done
    '';
  });

  allExtensions = upstream ++ builtins.attrValues custom;
in
{
  # Declaratively installed GNOME Shell extensions.
  environment.systemPackages = allExtensions ++ [ hicolor-with-caffeine-icons ];

  # Also enabled by default. These are dconf *defaults* (the system-db sits
  # below the user-db), so the user can still toggle any extension in
  # Extension Manager. Note `enabled-extensions` is a list-typed key, so any
  # manual toggle writes the whole list to the user db and overrides these.
  modules.gnome.dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = map (e: e.extensionUuid) allExtensions;
    };

    # Ported from the previous user-side (manual) Dynamic Music Pill install.
    # Playback history / first-hint state are intentionally not managed.
    "org/gnome/shell/extensions/dynamic-music-pill" = {
      enable-shadow = false;
      enable-transparency = true;
      hide-text = false;
      panel-pill-width = gv.mkInt32 310;
      popup-custom-width = gv.mkInt32 360;
      popup-follow-transparency = false;
      show-pill-border = true;
      target-container = gv.mkInt32 1;
      transparency-art = false;
      transparency-strength = gv.mkInt32 0;
      transparency-text = false;
      transparency-vis = false;
      visualizer-bars = gv.mkInt32 9;
      visualizer-height = gv.mkInt32 44;
      visualizer-style = gv.mkInt32 3;
    };
  };
}
