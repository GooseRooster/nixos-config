{ lib, ... }:

# Desktop plumbing shared by the noctalia session stack. A host imports this
# plus the session stack modules (noctalia.nix + sway.nix) to get a complete
# desktop.
{
  imports = [
    ./apps.nix
    ./terminal.nix
    ./graphics.nix
    ./gsr.nix
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
