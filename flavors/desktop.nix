{ inputs, ... }:

{
  imports = [
    ./base.nix
    ../modules/desktop/gnome.nix
    ../modules/desktop/gnome-devtools.nix
    ../modules/desktop/gnome-extensions.nix
    ../modules/desktop/gnome-settings.nix
    ../modules/desktop/terminal.nix
    ../modules/desktop/graphics.nix
    ../modules/desktop/portals.nix
    ../modules/desktop/pipewire.nix
    ../modules/desktop/keyring.nix
    ../modules/desktop/power.nix
    ../modules/desktop/virtualization.nix

    inputs.cli.nixosModules.dev
    inputs.cli.nixosModules.base-extra
    inputs.cli.nixosModules.ssh
    inputs.cli.nixosModules.podman
  ];

  modules.users.extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "render"
    "input"
    "audio"
    "libvirtd"
  ];

  modules.graphics.enable = true;
}
