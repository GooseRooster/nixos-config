{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openssh ];

  # SSH agent is provided by gcr-ssh-agent on the desktop
  # (services.gnome.gcr-ssh-agent, see modules/desktop/keyring.nix).
  # Do NOT also enable programs.ssh.startAgent — the two conflict.
  #
  # For a non-desktop flavor (e.g. WSL) without it, enable it here:
  #   programs.ssh.startAgent = true;
}
