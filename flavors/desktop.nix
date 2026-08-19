{ inputs, ... }:

{
  imports = [
    ./base.nix
    ../modules/desktop/scroll.nix
    ../modules/desktop/uwsm.nix
    ../modules/desktop/noctalia.nix
    ../modules/desktop/greeter.nix
    ../modules/desktop/portals.nix
    ../modules/desktop/pipewire.nix
    ../modules/desktop/keyring.nix
    ../modules/desktop/power.nix

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
  ];
}
