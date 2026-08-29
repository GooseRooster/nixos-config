{ lib, ... }:

# Base/essential Flatpaks — from chezmoi's base.flatpak.Brewfile.
# Enabled per-host via `modules.flatpak.base.enable = true`.
{
  imports = [ ./default.nix ];

  modules.flatpak.base.packages = [
    "io.mpv.Mpv"
    "be.alexandervanhee.gradia"
    "com.github.PintaProject.Pinta"
    "com.github.tchx84.Flatseal"
    "de.leopoldluley.Clapgrep"
    "io.github.bhack.mini-eq"
    "io.github.flattool.Ignition"
    "io.github.flattool.Warehouse"
    "io.github.kolunmi.Bazaar"
    "io.github.nokse22.high-tide"
    "io.github.pwr_solaar.solaar"
    "io.github.tanaybhomia.Whisp"
    "io.github.totoshko88.RustConn"
    "io.github.ungoogled_software.ungoogled_chromium"
    "io.missioncenter.MissionCenter"
    "it.mijorus.gearlever"
    "io.gitlab.adhami3310.Impression"
    "me.iepure.devtoolbox"
    "org.gimp.GIMP"
    "org.gnome.Boxes"
    "org.gnome.Builder"
    "org.gnome.Calculator"
    "org.gnome.Calendar"
    "org.gnome.Characters"
    "org.gnome.Connections"
    "org.gnome.Decibels"
    "org.gnome.DejaDup"
    "org.gnome.FileRoller"
    "org.gnome.Firmware"
    "org.gnome.Logs"
    "org.gnome.Loupe"
    "org.gnome.Maps"
    "org.gnome.Papers"
    "org.gnome.SimpleScan"
    "org.gnome.Snapshot"
    "org.gnome.SoundRecorder"
    "org.gnome.TextEditor"
    "org.gnome.Weather"
    "org.gnome.baobab"
    "org.gnome.clocks"
    "org.gnome.font-viewer"
    "org.gnome.seahorse.Application"
    "org.mozilla.thunderbird_esr"
    "com.usebottles.bottles"
    "com.protonvpn.www"
    "com.rafaelmardojai.Blanket"
    # GTK theme extensions: sandboxed GTK3 apps can't see host themes, so the
    # adw-gtk3 theme must be installed into flatpak land for them (Boxes,
    # seahorse, thunderbird, ...). Flatpak auto-mounts the matching branch per
    # app runtime. Libadwaita (GTK4) flatpaks read the host
    # ~/.config/gtk-4.0/gtk.css overlay instead and don't need these.
    "org.gtk.Gtk3theme.adw-gtk3"
    "org.gtk.Gtk3theme.adw-gtk3-dark"
  ];
}
