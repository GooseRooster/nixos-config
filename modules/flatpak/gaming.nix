{ lib, ... }:

# Gaming Flatpaks
# Enabled per-host via `modules.flatpak.gaming.enable = true`.
# Omit/disable on hosts that don't game (e.g. a workstation).
{
  imports = [ ./default.nix ];

  modules.flatpak.gaming.packages = [
    "com.dec05eba.gpu_screen_recorder"
    "com.vysp3r.ProtonPlus"
    "dev.vencord.Vesktop"
    "net.pcsx2.PCSX2"
    "org.DolphinEmu.dolphin-emu"
  ];
}
