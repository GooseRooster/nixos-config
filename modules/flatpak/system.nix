{ lib, ... }:

# System-wide Flatpaks: the kind of apps a normal distribution
# ships out of the box (GNOME core apps, media player, app store, browser
# support, theme extensions). These are considered part of the baseline
# machine rather than a user preference, so they stay on the system side and
# install for every user.
#
# User-facing / opinionated apps live in the home-manager repo instead
# (modules/flatpak.nix, installed per-user via nix-flatpak's HM module).
#
# Enabled per-host via `modules.flatpak.system.enable = true`.
{
  imports = [ ./default.nix ];

  modules.flatpak.system.packages = [
    # Media player + app store: baseline desktop programs.
    "io.mpv.Mpv"
    "io.github.kolunmi.Bazaar"

    # GNOME core apps.
    "org.gnome.Calculator"
    "org.gnome.Calendar"
    "org.gnome.Characters"
    "org.gnome.clocks"
    "org.gnome.Weather"
    "org.gnome.Maps"
    "org.gnome.Papers"
    "org.gnome.Loupe"
    "org.gnome.Snapshot"
    "org.gnome.SoundRecorder"
    "org.gnome.TextEditor"
    "org.gnome.FileRoller"
    "org.gnome.baobab"
    "org.gnome.font-viewer"
    "org.gnome.Decibels"
    "org.gnome.Logs"
    "org.gnome.SimpleScan"
    "org.gnome.Connections"
    "org.gnome.Firmware"
    "org.gnome.Boxes"
    "org.gnome.DejaDup"
    "org.gnome.seahorse.Application"

    # Messaging / VPN.
    "org.mozilla.thunderbird_esr"
    "com.protonvpn.www"

    # Flatpak + autostart management (system tooling).
    "com.github.tchx84.Flatseal"
    "io.github.flattool.Warehouse"
    "io.github.flattool.Ignition"

    # GTK theme extensions: sandboxed GTK3 apps can't see host themes, so the
    # adw-gtk3 theme must be installed into flatpak land for them (Boxes,
    # seahorse, thunderbird, ...). Flatpak auto-mounts the matching branch per
    # app runtime. Libadwaita (GTK4) flatpaks read the host
    # ~/.config/gtk-4.0/gtk.css overlay instead and don't need these.
    "org.gtk.Gtk3theme.adw-gtk3"
    "org.gtk.Gtk3theme.adw-gtk3-dark"
  ];
}
