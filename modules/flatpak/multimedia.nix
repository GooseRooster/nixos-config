{ lib, ... }:

# Multimedia Flatpaks — from chezmoi's multimedia.flatpak.Brewfile.
# Enabled per-host via `modules.flatpak.multimedia.enable = true`.
{
  imports = [ ./default.nix ];

  modules.flatpak.multimedia.packages = [
    "com.stremio.Stremio"
  ];
}
