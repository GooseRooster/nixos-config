{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    {
      # Identify the stack this module provides (see session.nix). mkDefault
      # so a host can still pin it explicitly; importing both stacks surfaces
      # the conflict loudly at eval time.
      modules.desktop.session = lib.mkDefault "gnome";
    }

    (lib.mkIf (config.modules.desktop.session == "gnome") {
    # GDM + GNOME (both Wayland-only since GNOME 50).
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Minimal GNOME: applications come from Flatpaks (see modules/flatpak),
    # shared apps live in apps.nix.
    services.gnome.core-apps.enable = false;
    services.gnome.games.enable = false;

    # gnome-disks has no Flatpak on Flathub, so it stays from nixpkgs.
    # (This would otherwise be pulled in by core-apps.)
    programs.gnome-disks.enable = true;

    # Refine is native: its flatpak strips /usr/share from XDG_DATA_DIRS and
    # re-reads host schemas via /run/host, which can't see NixOS store paths,
    # so every setting renders greyed out. It is a GNOME-specific tweaking
    # tool, so it stays GNOME-only (unlike the shared apps).
    environment.systemPackages = [
      pkgs.refine
    ];

    # Optional sub-services are left at their defaults (enabled):
    #   gnome-remote-desktop, gnome-user-share, rygel, gnome-initial-setup,
    #   gnome-online-accounts, evolution-data-server, dleyna,
    #   localsearch/tinysparql, gnome-browser-connector, geoclue2, colord, avahi.
    # Disable any here if a leaner install is wanted later.

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour        # first-login tour
      gnome-user-docs   # Help docs
      orca              # screen reader
      # gnome-bluetooth # uncomment on hosts WITHOUT bluetooth hardware
    ];
    })
  ];
}
