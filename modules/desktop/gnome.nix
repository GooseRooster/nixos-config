{ config, lib, pkgs, ... }:

{
  # GDM + GNOME (both Wayland-only since GNOME 50).
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Minimal GNOME: applications come from Flatpaks (see modules/flatpak).
  services.gnome.core-apps.enable = false;
  services.gnome.games.enable = false;

  # gnome-disks has no Flatpak on Flathub, so it stays from nixpkgs.
  # (This would otherwise be pulled in by core-apps.)
  programs.gnome-disks.enable = true;

  # Nautilus (Files) + Sushi (previewer): the org.gnome.Nautilus flatpak is
  # deprecated, so install from nixpkgs instead (normally pulled by core-apps).
  # Refine is also native: its flatpak strips /usr/share from XDG_DATA_DIRS and
  # re-reads host schemas via /run/host, which can't see NixOS store paths, so
  # every setting renders greyed out.
  environment.systemPackages = [
    pkgs.nautilus
    pkgs.refine
  ];
  services.gnome.sushi.enable = true;
  xdg.mime.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

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

  # Emoji + general fallback fonts (GNOME only ships adwaita-fonts by default).
  # CJK users may also want: noto-fonts-cjk-sans, noto-fonts-cjk-serif.
  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    noto-fonts
    nerd-fonts.jetbrains-mono
  ];
}
