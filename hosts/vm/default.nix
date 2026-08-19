{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../flavors/desktop.nix
  ];

  networking.hostName = "nixos";

  modules.users.primary = "gooze";
  # Only until `passwd gooze` sets a real one; initialPassword applies only
  # while the account has no password set.
  modules.users.initialPassword = "changeme";

  # Easy shell access from the host (`ssh gooze@<vm-ip>`) — sidesteps the
  # Boxes TTY-switch problem entirely.
  services.openssh.enable = true;

  # QEMU/Spice guest integration (this is a VM).
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # No bluetooth hardware in this VM.
  hardware.bluetooth.enable = false;

  system.stateVersion = "26.05";
}
