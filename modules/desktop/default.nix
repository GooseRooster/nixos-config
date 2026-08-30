{ lib, ... }:

# Desktop plumbing shared by every session stack (GNOME and noctalia alike).
# A host imports this plus exactly one session stack module
# (gnome.nix / noctalia.nix) to get a complete desktop.
{
  imports = [
    ./session.nix
    ./apps.nix
    ./terminal.nix
    ./graphics.nix
    ./portals.nix
    ./pipewire.nix
    ./keyring.nix
    ./power.nix
    ./virtualization.nix
  ];

  modules.graphics.enable = true;

  # Desktop session groups (overridable per host via mkForce / plain list).
  modules.users.extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "render"
    "input"
    "audio"
    "libvirtd"
  ];
}
