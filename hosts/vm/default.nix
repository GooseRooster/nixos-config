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

  # QEMU/Boxes without GPU acceleration: wlroots needs an explicit opt-in to
  # software rendering, or scroll fails to init EGL and the session never
  # comes up. (Merges with the shared extraSessionCommands in scroll.nix.)
  programs.scroll.extraSessionCommands = ''
    export WLR_RENDERER_ALLOW_SOFTWARE=1
  '';

  system.stateVersion = "26.05";
}
