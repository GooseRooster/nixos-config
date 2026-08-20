{ config, pkgs, lib, ... }:

{
  # gnome-keyring + gcr-ssh-agent are enabled by GNOME's core-os-services.
  # GDM's gdm-password substacks `login` and gdm-autologin reads
  # login.enableGnomeKeyring to inject pam_gnome_keyring.so, so enabling it on
  # the `login` service unlocks the keyring at both GDM and TTY login.
  security.pam.services.login.enableGnomeKeyring = true;
}
