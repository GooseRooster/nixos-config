{ lib, ... }:

# Gaming Flatpaks — from chezmoi's gaming.flatpak.Brewfile.
# Enabled per-host via `modules.flatpak.gaming.enable = true`.
# Omit/disable on hosts that don't game (e.g. a workstation).
{
  imports = [ ./default.nix ];

  modules.flatpak.gaming.packages = [
    "com.dec05eba.gpu_screen_recorder"
    # Steam is native now (modules/gaming/steam.nix): Millennium does not
    # support the Flatpak Steam. AdwSteamGtk is gone too — Millennium owns
    # Steam theming.
    # Wine, winetricks and Faugus Launcher are native too (modules/gaming/wine.nix).
    "com.vysp3r.ProtonPlus"
    "dev.vencord.Vesktop"
    "io.github.ilya_zlobintsev.LACT"
    "net.pcsx2.PCSX2"
    "org.DolphinEmu.dolphin-emu"
  ];
}
