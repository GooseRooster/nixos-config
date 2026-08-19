{ inputs, ... }:

{
  imports = [
    ./base.nix
    inputs.cli.nixosModules.dev
    inputs.cli.nixosModules.ssh
  ];

  # WSL flavor: no GUI, no greeter, no podman system service.
  # Add WSL-specific bits here later (e.g. boot.isContainer, networking).
}
