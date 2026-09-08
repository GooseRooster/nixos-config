{ lib, ... }:

# Desktop plumbing shared by every host. A host imports this plus the GNOME
# stack modules (gnome.nix + gnome-settings.nix + gnome-devtools.nix +
# gnome-extensions.nix) to get a complete desktop.
{
  imports = [
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
