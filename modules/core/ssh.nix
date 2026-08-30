{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openssh ];

  # SSH agent is provided by gnome-keyring on the desktop
  # (services.gnome.gcr-ssh-agent, enabled by default with gnome-keyring).
  # Do NOT also enable programs.ssh.startAgent — the two conflict.
  #
  # For a non-desktop flavor (e.g. WSL) without gnome-keyring, enable it here:
  #   programs.ssh.startAgent = true;
}
