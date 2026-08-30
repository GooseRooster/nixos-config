{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop/default.nix
    ../../modules/desktop/gnome.nix
    ../../modules/desktop/gnome-devtools.nix
    ../../modules/desktop/gnome-settings.nix
    ../../modules/desktop/gnome-extensions.nix
    ../../modules/core/podman.nix
    ../../modules/flatpak/base.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  modules.flatpak.enable = true;
  modules.flatpak.base.enable = true;

  modules.users.primary = "gooze";

  # Home dotfiles — desktop shell/editor, but no gaming/theming (this VM has
  # neither the flatpaks nor the theming extras). podmanAlias on: lazydocker
  # needs the rootless socket + DOCKER_HOST (dockerCompat only gives rootful).
  home-manager.users.gooze = {
    imports = [ inputs.dotfiles.hmModules.default ];
    # Desktop extras (fonts, vscode, fastfetch, …). bundles.base is default-on.
    home.bundles.baseExtra.enable = true;
    home.modules.podmanAlias.enable = true;
  };
  # Only until `passwd gooze` sets a real one; initialPassword applies only
  # while the account has no password set.
  modules.users.initialPassword = "changeme";

  # Easy shell access from the host (`ssh gooze@<vm-ip>`) — sidesteps the
  # Boxes TTY-switch problem entirely.
  # NOTE: hardening disables password auth, so provision an SSH key first
  # (`ssh-copy-id gooze@<vm-ip>` after setting the password), or temporarily
  # comment out services.openssh.settings in modules/core/hardening.nix.
  services.openssh.enable = true;

  # QEMU/Spice guest integration (this is a VM).
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # No bluetooth hardware in this VM.
  hardware.bluetooth.enable = false;

  # Plain nixpkgs kernel for the VM. `latest` is the default, but set it here
  # explicitly to document the per-host kernel selection path.
  modules.kernel.variant = "latest";

  # GNOME in Boxes needs 3D acceleration (virtio-gpu / virgl) enabled in the
  # VM settings, otherwise the session may fail to start.

  system.stateVersion = "26.05";
}
