{ config, pkgs, lib, ... }:

{
  # Secret Service provider (org.freedesktop.secrets).
  # Also provides the SSH agent (services.gnome.gcr-ssh-agent defaults to on).
  services.gnome.gnome-keyring.enable = true;

  # Unlock the keyring at login (greeter + TTY).
  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };
}
