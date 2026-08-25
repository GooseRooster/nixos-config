{ lib, ... }:

# Gaming Flatpaks — from chezmoi's gaming.flatpak.Brewfile.
# Enabled per-host via `modules.flatpak.gaming.enable = true`.
# Omit/disable on hosts that don't game (e.g. a workstation).
{
  imports = [ ./default.nix ];

  modules.flatpak.gaming.packages = [
    "com.dec05eba.gpu_screen_recorder"
    "com.valvesoftware.Steam"
    "com.vysp3r.ProtonPlus"
    "dev.vencord.Vesktop"
    "io.github.Foldex.AdwSteamGtk"
    "io.github.ilya_zlobintsev.LACT"
    "net.pcsx2.PCSX2"
    "org.DolphinEmu.dolphin-emu"
    "io.github.Faugus.faugus-launcher"
    # Pin the branch: Flathub ships org.winehq.Wine under many branches
    # (stable-*, wow64-*), and an unpinned `flatpak install` fails with
    # "Multiple refs match" in non-interactive mode.
    "org.winehq.Wine//wow64-25.08"
  ];
}
